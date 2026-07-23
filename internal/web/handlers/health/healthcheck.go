package health

import (
	"net/http"
	"time"

	"github.com/thomiceli/opengist/internal/db"
	"github.com/thomiceli/opengist/internal/web/context"
)

// Index returns a lightweight 200 OK response, intended for HEAD requests to
// the root path "/". This is useful for uptime monitors and load balancers that
// poll the application with HEAD requests (e.g. `curl -I`).
func Index(ctx *context.Context) error {
	return ctx.NoContent(http.StatusOK)
}

func Healthcheck(ctx *context.Context) error {
	// Check database connection
	dbOk := "ok"
	httpStatus := 200

	err := db.Ping()
	if err != nil {
		dbOk = "ko"
		httpStatus = 503
	}

	return ctx.JSON(httpStatus, map[string]interface{}{
		"opengist": "ok",
		"database": dbOk,
		"time":     time.Now().Format(time.RFC3339),
	})
}
