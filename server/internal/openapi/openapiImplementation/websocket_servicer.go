package openapiImplementation

import (
	"encoding/json"
	"fmt"
	"net/http"
	"sync"
	"time"
	"verni/internal/controllers/auth"
	openapi "verni/internal/openapi/go"
	"verni/internal/services/logging"
	"verni/internal/services/realtimeEvents"
)

type connectionDescriptor struct {
	userId realtimeEvents.UserId
	device realtimeEvents.DeviceId
}

type websocketHandler struct {
	eventService     realtimeEvents.Service
	logger           logging.Service
	auth             auth.Controller
	connectionsMutex sync.RWMutex
	connections      map[connectionDescriptor][]chan string
}

func (h *websocketHandler) Handle(w http.ResponseWriter, r *http.Request) {
	sessionInfo, earlyResponse := validateToken(h.logger, h.auth, r.Header.Get("Authorization"))
	if earlyResponse != nil {
		errJSON, err := json.MarshalIndent(earlyResponse.Body, "", " ")
		if err != nil {
			http.Error(w, string(openapi.INTERNAL), http.StatusInternalServerError)
			return
		}
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(earlyResponse.Code)
		w.Write(errJSON)
		return
	}
	// Set headers for SSE
	w.Header().Set("Content-Type", "text/event-stream")
	w.Header().Set("Cache-Control", "no-cache")
	w.Header().Set("Connection", "keep-alive")
	w.Header().Set("Access-Control-Allow-Origin", "*")

	// Store connection
	descriptor := connectionDescriptor{
		userId: realtimeEvents.UserId(sessionInfo.User),
		device: realtimeEvents.DeviceId(sessionInfo.Device),
	}
	// Create channel for this client
	messageChan := make(chan string, 10)

	// Register client
	h.connectionsMutex.Lock()
	h.connections[descriptor] = append(h.connections[descriptor], messageChan)
	h.connectionsMutex.Unlock()

	// Ensure cleanup on disconnect
	defer func() {
		h.connectionsMutex.Lock()
		defer h.connectionsMutex.Unlock()

		// Remove this client's channel
		if channels, exists := h.connections[descriptor]; exists {
			for i, ch := range channels {
				if ch == messageChan {
					h.connections[descriptor] = append(channels[:i], channels[i+1:]...)
					break
				}
			}
			// Clean up if no more channels for this user
			if len(h.connections[descriptor]) == 0 {
				delete(h.connections, descriptor)
			}
		}
		close(messageChan)
	}()

	// Send initial connection established message
	fmt.Fprintf(w, "data: {\"type\": \"connected\"}\n\n")
	if f, ok := w.(http.Flusher); ok {
		f.Flush()
	}

	// Keep connection alive and send updates
	for {
		select {
		case msg := <-messageChan:
			fmt.Fprint(w, msg)
			if f, ok := w.(http.Flusher); ok {
				f.Flush()
			}
		case <-r.Context().Done():
			return
		}
	}
}

func (h *websocketHandler) handleUpdate(userId realtimeEvents.UserId, device realtimeEvents.DeviceId) {
	h.connectionsMutex.RLock()
	defer h.connectionsMutex.RUnlock()

	if channels, exists := h.connections[connectionDescriptor{userId: userId, device: device}]; exists {
		update := fmt.Sprintf("data: {\"userId\": \"%s\", \"timestamp\": %d}\n\n",
			userId, time.Now().Unix())

		for _, ch := range channels {
			// Non-blocking send
			select {
			case ch <- update:
			default:
				// Channel is full or closed
			}
		}
	}
}

func NewWebsocketHandler(
	service realtimeEvents.Service,
	auth auth.Controller,
	logger logging.Service,
) func(w http.ResponseWriter, r *http.Request) {
	handler := &websocketHandler{
		eventService: service,
		connections:  make(map[connectionDescriptor][]chan string),
		logger:       logger,
		auth:         auth,
	}
	handler.eventService.AddListener(handler.handleUpdate)
	return handler.Handle
}
