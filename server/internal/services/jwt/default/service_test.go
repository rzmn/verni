package defaultJwtService_test

import (
	"errors"
	"testing"
	"time"

	"verni/internal/services/jwt"
	defaultJwtService "verni/internal/services/jwt/default"
	standartOutputLoggingService "verni/internal/services/logging/standartOutput"

	"github.com/google/uuid"
)

type testService struct {
	service jwt.Service
	config  defaultJwtService.DefaultConfig
}

func setupTestService(currentTime func() time.Time) testService {
	config := defaultJwtService.DefaultConfig{
		RefreshTokenLifetimeHours: 24 * 30, // 30 days
		AccessTokenLifetimeHours:  1,       // 1 hour
		RefreshTokenSecret:        "RefreshTokenSecret",
		AccessTokenSecret:         "AccessTokenSecret",
	}

	return testService{
		service: defaultJwtService.New(
			config,
			standartOutputLoggingService.New(),
			currentTime,
		),
		config: config,
	}
}

func generateSubject() jwt.Subject {
	return jwt.Subject{
		User:   jwt.UserId(uuid.New().String()),
		Device: jwt.DeviceId(uuid.New().String()),
	}
}

func TestTokenIssuance(t *testing.T) {
	t.Run("refresh token issuance and validation", func(t *testing.T) {
		svc := setupTestService(time.Now)
		subject := generateSubject()

		token, err := svc.service.IssueRefreshToken(subject)
		if err != nil {
			t.Fatalf("failed to issue refresh token: %v", err)
		}

		if err := svc.service.ValidateRefreshToken(token); err != nil {
			t.Errorf("failed to validate refresh token: %v", err)
		}

		gotSubject, err := svc.service.GetRefreshTokenSubject(token)
		if err != nil {
			t.Fatalf("failed to get subject from refresh token: %v", err)
		}
		if gotSubject != subject {
			t.Errorf("got subject %v, want %v", gotSubject, subject)
		}
	})

	t.Run("access token issuance and validation", func(t *testing.T) {
		svc := setupTestService(time.Now)
		subject := generateSubject()

		token, err := svc.service.IssueAccessToken(subject)
		if err != nil {
			t.Fatalf("failed to issue access token: %v", err)
		}

		if err := svc.service.ValidateAccessToken(token); err != nil {
			t.Errorf("failed to validate access token: %v", err)
		}

		gotSubject, err := svc.service.GetAccessTokenSubject(token)
		if err != nil {
			t.Fatalf("failed to get subject from access token: %v", err)
		}
		if gotSubject != subject {
			t.Errorf("got subject %v, want %v", gotSubject, subject)
		}
	})
}

func TestTokenTypeValidation(t *testing.T) {
	t.Run("refresh token cannot be used as access token", func(t *testing.T) {
		svc := setupTestService(time.Now)
		subject := generateSubject()

		refreshToken, _ := svc.service.IssueRefreshToken(subject)

		err := svc.service.ValidateAccessToken(jwt.AccessToken(refreshToken))
		if !errors.Is(err, jwt.BadToken) {
			t.Errorf("expected BadToken error, got %v", err)
		}

		_, err = svc.service.GetAccessTokenSubject(jwt.AccessToken(refreshToken))
		if !errors.Is(err, jwt.BadToken) {
			t.Errorf("expected BadToken error, got %v", err)
		}
	})

	t.Run("access token cannot be used as refresh token", func(t *testing.T) {
		svc := setupTestService(time.Now)
		subject := generateSubject()

		accessToken, _ := svc.service.IssueAccessToken(subject)

		err := svc.service.ValidateRefreshToken(jwt.RefreshToken(accessToken))
		if !errors.Is(err, jwt.BadToken) {
			t.Errorf("expected BadToken error, got %v", err)
		}

		_, err = svc.service.GetRefreshTokenSubject(jwt.RefreshToken(accessToken))
		if !errors.Is(err, jwt.BadToken) {
			t.Errorf("expected BadToken error, got %v", err)
		}
	})
}

func TestTokenExpiration(t *testing.T) {
	t.Run("expired refresh token", func(t *testing.T) {
		// Set time to after refresh token expiration
		expiredTime := func() time.Time {
			return time.Now().Add(-31 * 24 * time.Hour) // 31 days ago
		}
		svc := setupTestService(expiredTime)

		token, _ := svc.service.IssueRefreshToken(generateSubject())

		err := svc.service.ValidateRefreshToken(token)
		if !errors.Is(err, jwt.TokenExpired) {
			t.Errorf("expected TokenExpired error, got %v", err)
		}
	})

	t.Run("expired access token", func(t *testing.T) {
		// Set time to after access token expiration
		expiredTime := func() time.Time {
			return time.Now().Add(-2 * time.Hour) // 2 hours ago
		}
		svc := setupTestService(expiredTime)

		token, _ := svc.service.IssueAccessToken(generateSubject())

		err := svc.service.ValidateAccessToken(token)
		if !errors.Is(err, jwt.TokenExpired) {
			t.Errorf("expected TokenExpired error, got %v", err)
		}
	})

	t.Run("tokens valid just before expiration", func(t *testing.T) {
		// Set time to just before expiration
		almostExpiredTime := func() time.Time {
			return time.Now().Add(-55 * time.Minute) // 55 minutes ago
		}
		svc := setupTestService(almostExpiredTime)
		subject := generateSubject()

		accessToken, _ := svc.service.IssueAccessToken(subject)
		if err := svc.service.ValidateAccessToken(accessToken); err != nil {
			t.Errorf("access token should be valid: %v", err)
		}

		refreshToken, _ := svc.service.IssueRefreshToken(subject)
		if err := svc.service.ValidateRefreshToken(refreshToken); err != nil {
			t.Errorf("refresh token should be valid: %v", err)
		}
	})
}
