package httpapi

import (
	"encoding/json"
	"log"
	"net/http"
	"net/http/httputil"
	"net/url"
	"strings"

	"github.com/go-chi/chi/v5"
)

type Handler struct {
	AuthURL      string
	TenantURL    string
	BusinessURL  string
	CatalogURL   string
	OrderURL     string
	InventoryURL string
	LegalURL     string
	AIURL        string
	JWTSecret    string
}

func NewRouter(h *Handler) http.Handler {
	r := chi.NewRouter()

	r.Get("/health", h.health)
	r.Get("/", h.apiInfo)

	r.Mount(
		"/api/v1/auth",
		proxyPreservePath(h.AuthURL),
	)

	r.Mount(
		"/api/v1/tenants",
		proxyPreservePath(h.TenantURL),
	)

	r.Mount(
		"/api/v1/businesses",
		proxyPreservePath(h.BusinessURL),
	)

	r.Mount(
		"/api/v1/catalog",
		proxyPreservePath(h.CatalogURL),
	)

	r.Mount(
		"/api/v1/orders",
		proxyPreservePath(h.OrderURL),
	)

	r.Mount(
		"/api/v1/ai",
		proxyPreservePath(h.AIURL),
	)

	// Public read-only marketplace facade.
	// No JWT middleware.
	r.Mount(
		"/api/v1/marketplace",
		proxyPreservePath(h.BusinessURL),
	)

	r.Route("/api/v1/legal", func(r chi.Router) {
		r.Use(JWTMiddleware(h.JWTSecret))

		r.Handle(
			"/*",
			proxyPreservePath(h.LegalURL),
		)
	})

	return r
}

func (h *Handler) health(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, map[string]any{
		"success": true,
		"data": map[string]any{
			"service": "api_gateway",
			"status":  "healthy",
			"version": "0.3.0",
		},
	})
}

func (h *Handler) apiInfo(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, map[string]any{
		"service": "api_gateway",
		"version": "0.3.0",
		"routes": []string{
			"/api/v1/auth/*",
			"/api/v1/tenants/*",
			"/api/v1/businesses/*",
			"/api/v1/catalog/*",
			"/api/v1/orders/*",
			"/api/v1/ai/*",
			"/api/v1/marketplace/*",
			"/api/v1/inventory/*",
			"/api/v1/legal/*",
		},
	})
}

func proxyPreservePath(rawURL string) http.Handler {
	target, err := url.Parse(rawURL)
	if err != nil {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			http.Error(w, "upstream service unavailable", http.StatusBadGateway)
		})
	}

	proxy := httputil.NewSingleHostReverseProxy(target)
	originalDirector := proxy.Director

	proxy.Director = func(req *http.Request) {
		incomingPath := req.URL.Path
		incomingQuery := req.URL.RawQuery

		originalDirector(req)

		log.Printf(
			"PROXY method=%s incoming_path=%s incoming_query=%s upstream=%s://%s%s?%s",
			req.Method,
			incomingPath,
			incomingQuery,
			req.URL.Scheme,
			req.URL.Host,
			req.URL.Path,
			req.URL.RawQuery,
		)
	}

	proxy.ErrorHandler = func(
		w http.ResponseWriter,
		r *http.Request,
		err error,
	) {
		log.Printf("proxy error target=%s error=%v", rawURL, err)
		http.Error(w, "upstream service unavailable", http.StatusBadGateway)
	}

	return proxy
}

func proxy(rawURL, prefix string) http.Handler {
	target, err := url.Parse(rawURL)
	if err != nil {
		log.Printf(
			"invalid proxy target %s: %v",
			rawURL,
			err,
		)

		return http.HandlerFunc(func(
			w http.ResponseWriter,
			r *http.Request,
		) {
			http.Error(
				w,
				"invalid upstream configuration",
				http.StatusBadGateway,
			)
		})
	}

	p := httputil.NewSingleHostReverseProxy(target)

	originalDirector := p.Director

	p.Director = func(req *http.Request) {
		originalDirector(req)

		req.URL.Path = strings.TrimPrefix(
			req.URL.Path,
			prefix,
		)

		if req.URL.Path == "" {
			req.URL.Path = "/"
		}
	}

	p.ErrorHandler = func(
		w http.ResponseWriter,
		r *http.Request,
		err error,
	) {
		log.Printf(
			"proxy error target=%s path=%s error=%v",
			rawURL,
			r.URL.Path,
			err,
		)

		http.Error(
			w,
			"upstream service unavailable",
			http.StatusBadGateway,
		)
	}

	return p
}

func writeJSON(
	w http.ResponseWriter,
	status int,
	value any,
) {
	w.Header().Set(
		"Content-Type",
		"application/json",
	)

	w.WriteHeader(status)

	if err := json.NewEncoder(w).Encode(value); err != nil {
		log.Printf(
			"json response error: %v",
			err,
		)
	}
}
