package openapiImplementation

import (
	"encoding/json"
	"fmt"
	"net/http"
	"sync"
	"time"
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
	devicesPerUser   map[realtimeEvents.UserId]map[realtimeEvents.DeviceId]struct{}
}

const (
	channelBuffer = 10
	// Add a reasonable timeout for message sending
	messageTimeout = 100 * time.Millisecond
)

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
	messageChan := make(chan string, channelBuffer)

	// Register client
	h.connectionsMutex.Lock()
	if h.devicesPerUser[descriptor.userId] == nil {
		h.devicesPerUser[descriptor.userId] = make(map[realtimeEvents.DeviceId]struct{})
	}
	h.connections[descriptor] = append(h.connections[descriptor], messageChan)
	h.devicesPerUser[descriptor.userId][descriptor.device] = struct{}{}
	h.connectionsMutex.Unlock()

	// Ensure cleanup on disconnect
	defer func() {
		h.logger.LogInfo("%s: cleaning up connection for descriptor: %v", op, descriptor)

		h.connectionsMutex.Lock()

		// Remove this client's channel
		if channels, exists := h.connections[descriptor]; exists {
			newChannels := make([]chan string, 0, len(channels)-1)
			for _, ch := range channels {
				if ch != messageChan {
					newChannels = append(newChannels, ch)
				}
			}
			if len(newChannels) == 0 {
				delete(h.connections, descriptor)
				// Only remove from devicesPerUser if this was the last channel for this device
				delete(h.devicesPerUser[descriptor.userId], descriptor.device)
				if len(h.devicesPerUser[descriptor.userId]) == 0 {
					delete(h.devicesPerUser, descriptor.userId)
				}
			} else {
				h.connections[descriptor] = newChannels
			}
		}

		close(messageChan)
		h.connectionsMutex.Unlock()

		fmt.Fprintf(w, "data: {\"type\": \"disconnected\"}\n\n")
		if f, ok := w.(http.Flusher); ok {
			f.Flush()
		}
	}()

	// Send initial connection established message
	fmt.Fprintf(w, "data: {\"type\": \"connected\"}\n\n")
	if f, ok := w.(http.Flusher); ok {
		f.Flush()
	}

	var allDevicesExceptCurrent []realtimeEvents.DeviceId
	for device := range h.devicesPerUser[descriptor.userId] {
		if device != descriptor.device {
			allDevicesExceptCurrent = append(allDevicesExceptCurrent, device)
		}
	}
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
				h.logger.LogInfo("%s: unable to flush - connection might be closed for %v", op, descriptor)
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

	// Safety check for nil map
	devices, exists := h.devicesPerUser[userId]
	if !exists {
		h.logger.LogInfo("%s: no devices found for user %s", op, userId)
		return
	}

	h.logger.LogInfo("%s: handling update for %s - known devices: %v", op, userId, devices)
	for deviceId := range devices {
		if ignoringDevicesMap[deviceId] {
			continue
		}

		if channels, exists := h.connections[connectionDescriptor{userId: userId, device: deviceId}]; exists {
			operations, err := h.operations.Pull(operations.UserId(userId), operations.DeviceId(deviceId), openapi.REGULAR)

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

			var staleChan []int
			for i, ch := range channels {
				h.logger.LogInfo("%s: attempting to send update %s for channel for %s, %s", op, string(updateJSON), userId, deviceId)
				select {
				case ch <- string(updateJSON):
					h.logger.LogInfo("%s: successfully sent update for %s, %s", op, userId, deviceId)
				case <-time.After(messageTimeout):
					// Mark channel as stale if we can't send within timeout
					h.logger.LogInfo("%s: channel timeout for %s, %s - marking for cleanup", op, userId, deviceId)
					staleChan = append(staleChan, i)
				}
			}

			// Clean up stale channels if any were found
			if len(staleChan) > 0 {
				h.connectionsMutex.RUnlock()
				h.connectionsMutex.Lock()
				newChannels := make([]chan string, 0, len(channels)-len(staleChan))
				for i, ch := range channels {
					if !contains(staleChan, i) {
						newChannels = append(newChannels, ch)
					} else {
						close(ch)
					}
				}
				if len(newChannels) == 0 {
					delete(h.connections, connectionDescriptor{userId: userId, device: deviceId})
					delete(h.devicesPerUser[userId], deviceId)
					if len(h.devicesPerUser[userId]) == 0 {
						delete(h.devicesPerUser, userId)
					}
				} else {
					h.connections[connectionDescriptor{userId: userId, device: deviceId}] = newChannels
				}
				h.connectionsMutex.Unlock()
				h.connectionsMutex.RLock()
			}
		}
	}
}

// Helper function to check if slice contains an int
func contains(s []int, e int) bool {
	for _, a := range s {
		if a == e {
			return true
		}
	}
	return false
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
		devicesPerUser: make(map[realtimeEvents.UserId]map[realtimeEvents.DeviceId]struct{}),
		logger:         logger,
		auth:           auth,
		operations:     operations,
	}
	handler.eventService.AddListener(handler.handleUpdate)
	return handler.Handle
}
