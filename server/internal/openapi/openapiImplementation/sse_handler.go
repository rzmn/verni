package openapiImplementation

import (
	"encoding/json"
	"fmt"
	"net/http"
	"sync"
	"verni/internal/common"
	"verni/internal/controllers/auth"
	"verni/internal/controllers/operations"
	openapi "verni/internal/openapi/go"
	"verni/internal/services/logging"
	"verni/internal/services/realtimeEvents"
)

type connectionDescriptor struct {
	userId realtimeEvents.UserId
	device realtimeEvents.DeviceId
}

type sseHandler struct {
	eventService     realtimeEvents.Service
	logger           logging.Service
	auth             auth.Controller
	operations       operations.Controller
	connectionsMutex sync.RWMutex
	connections      map[connectionDescriptor][]chan string
	devicesPerUser   map[realtimeEvents.UserId][]realtimeEvents.DeviceId
}

func (h *sseHandler) Handle(w http.ResponseWriter, r *http.Request) {
	const op = "openapiImplementation.sseHandler.Handle"
	sessionInfo, earlyResponse := validateToken(h.logger, h.auth, r.Header.Get("Authorization"))
	if earlyResponse != nil {
		errJSON, err := json.Marshal(earlyResponse.Body)
		if err != nil {
			h.logger.LogError("%s: marshaling early response: %w", op, err)
			http.Error(w, string(openapi.INTERNAL), http.StatusInternalServerError)
			return
		}
		h.logger.LogInfo("%s: unable to open sse connection: %v", op, earlyResponse.Body)
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(earlyResponse.Code)
		w.Write(errJSON)
		return
	}
	h.logger.LogInfo("%s: opening sse connection for %s", op, sessionInfo.User)
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
	h.devicesPerUser[descriptor.userId] = append(h.devicesPerUser[descriptor.userId], descriptor.device)
	h.connectionsMutex.Unlock()

	// Ensure cleanup on disconnect
	defer func() {
		h.logger.LogError("%s: cleaning up connection for descriptor: %v", op, descriptor)
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
		h.devicesPerUser[descriptor.userId] = common.Filter(h.devicesPerUser[descriptor.userId], func(device realtimeEvents.DeviceId) bool {
			return device != descriptor.device
		})
		close(messageChan)
	}()

	// Send initial connection established message
	fmt.Fprintf(w, "data: {\"type\": \"connected\"}\n\n")
	if f, ok := w.(http.Flusher); ok {
		f.Flush()
	}

	allDevicesExceptCurrent := common.Filter(h.devicesPerUser[descriptor.userId], func(device realtimeEvents.DeviceId) bool {
		return device != descriptor.device
	})
	h.handleUpdate(descriptor.userId, allDevicesExceptCurrent)

	// Keep connection alive and send updates
	for {
		select {
		case msg := <-messageChan:
			h.logger.LogInfo("%s: sending %s for descriptor %v", op, msg, descriptor)
			fmt.Fprintf(w, "data: %s\n\n", msg)
			if f, ok := w.(http.Flusher); ok {
				f.Flush()
			} else {
				h.logger.LogError("%s: unable to flush - connection might be closed for %v", op, descriptor)
			}
		case <-r.Context().Done():
			h.logger.LogInfo("%s: context done for descriptor %v", op, descriptor)
			return
		}
	}
}

func (h *sseHandler) handleUpdate(userId realtimeEvents.UserId, ignoringDevices []realtimeEvents.DeviceId) {
	const op = "openapiImplementation.sseHandler.handleUpdate"
	h.logger.LogInfo("%s: handling update for %s, ignoring devices: %v", op, userId, ignoringDevices)
	h.connectionsMutex.RLock()
	defer h.connectionsMutex.RUnlock()

	ignoringDevicesMap := make(map[realtimeEvents.DeviceId]bool)
	for _, device := range ignoringDevices {
		ignoringDevicesMap[device] = true
	}
	h.logger.LogInfo("%s: handling update for %s - known devices: %v", op, userId, h.devicesPerUser[userId])
	for _, device := range h.devicesPerUser[userId] {
		if ignoringDevicesMap[device] {
			continue
		}

		if channels, exists := h.connections[connectionDescriptor{userId: userId, device: device}]; exists {
			operations, err := h.operations.Pull(operations.UserId(userId), operations.DeviceId(device), openapi.REGULAR)

			var update map[string]interface{}
			if err != nil {
				update = map[string]interface{}{
					"type":  "error",
					"error": handlePullOperationsError(h.logger, err),
				}
			} else {
				update = map[string]interface{}{
					"type":    "update",
					"update":  "operationsPulled",
					"payload": operations,
				}
			}
			updateJSON, err := json.Marshal(update)
			if err != nil {
				h.logger.LogError("%s: marshalling update: %v", op, err)
				return
			}

			for _, ch := range channels {
				h.logger.LogInfo("%s: attempting to send update %s for channel for %s, %s", op, string(updateJSON), userId, device)
				select {
				case ch <- string(updateJSON):
					h.logger.LogInfo("%s: successfully sent update for %s, %s", op, userId, device)
				default:
					h.logger.LogError("%s: channel full or closed for %s, %s - dropping message", op, userId, device)
				}
			}
		}
	}
}

func NewSSEHandler(
	service realtimeEvents.Service,
	auth auth.Controller,
	operations operations.Controller,
	logger logging.Service,
) func(w http.ResponseWriter, r *http.Request) {
	handler := &sseHandler{
		eventService:   service,
		connections:    make(map[connectionDescriptor][]chan string),
		devicesPerUser: make(map[realtimeEvents.UserId][]realtimeEvents.DeviceId),
		logger:         logger,
		auth:           auth,
		operations:     operations,
	}
	handler.eventService.AddListener(handler.handleUpdate)
	return handler.Handle
}
