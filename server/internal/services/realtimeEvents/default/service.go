package defaultRealtimeEvents

import (
	"sync"

	"verni/internal/services/realtimeEvents"
)

type userUpdateService struct {
	listeners []realtimeEvents.Listener
	mu        sync.RWMutex
}

func NewUserUpdateService() realtimeEvents.Service {
	return &userUpdateService{
		listeners: make([]realtimeEvents.Listener, 0),
	}
}

func (s *userUpdateService) AddListener(listener realtimeEvents.Listener) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.listeners = append(s.listeners, listener)
}

func (s *userUpdateService) NotifyUpdate(userId realtimeEvents.UserId, device realtimeEvents.DeviceId) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	for _, listener := range s.listeners {
		listener(userId, device)
	}
}
