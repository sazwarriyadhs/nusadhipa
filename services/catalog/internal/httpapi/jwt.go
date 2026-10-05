package httpapi

import (
	"errors"
	"strings"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

type catalogClaims struct {
	UserID   string `json:"user_id"`
	TenantID string `json:"tenant_id"`
	Role     string `json:"role"`
	jwt.RegisteredClaims
}

func parseToken(tokenString, secret string) (*catalogClaims, error) {
	tokenString = strings.TrimSpace(tokenString)

	if tokenString == "" {
		return nil, errors.New("empty token")
	}

	claims := &catalogClaims{}

	token, err := jwt.ParseWithClaims(
		tokenString,
		claims,
		func(token *jwt.Token) (interface{}, error) {
			if token.Method != jwt.SigningMethodHS256 {
				return nil, errors.New("unexpected signing method")
			}

			return []byte(secret), nil
		},
	)

	if err != nil {
		return nil, err
	}

	if !token.Valid {
		return nil, errors.New("invalid token")
	}

	if claims.UserID == "" {
		return nil, errors.New("missing user_id")
	}

	if claims.TenantID == "" {
		return nil, errors.New("missing tenant_id")
	}

	if claims.Role == "" {
		return nil, errors.New("missing role")
	}

	if claims.ExpiresAt != nil &&
		time.Now().After(claims.ExpiresAt.Time) {
		return nil, errors.New("token expired")
	}

	return claims, nil
}
