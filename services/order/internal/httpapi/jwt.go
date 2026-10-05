package httpapi

import (
	"errors"
	"strings"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

type jwtClaims struct {
	UserID   string `json:"user_id"`
	TenantID string `json:"tenant_id"`
	Role     string `json:"role"`
	jwt.RegisteredClaims
}

func parseToken(tokenString, secret string) (*jwtClaims, error) {
	tokenString = strings.TrimSpace(tokenString)

	if tokenString == "" {
		return nil, errors.New("empty token")
	}

	claims := &jwtClaims{}

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

	if claims.UserID == "" ||
		claims.TenantID == "" ||
		claims.Role == "" {
		return nil, errors.New("required claims missing")
	}

	if claims.ExpiresAt != nil &&
		time.Now().After(claims.ExpiresAt.Time) {
		return nil, errors.New("token expired")
	}

	return claims, nil
}
