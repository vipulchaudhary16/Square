package middleware

import (
	"encoding/json"
	"log"
	"time"

	"github.com/gofiber/fiber/v2"
)

func Logger() fiber.Handler {
	return func(c *fiber.Ctx) error {
		start := time.Now()

		// Capture request body
		var body interface{}
		if len(c.Body()) > 0 {
			if err := json.Unmarshal(c.Body(), &body); err != nil {
				body = string(c.Body())
			}
		}

		// Proceed to next middleware
		err := c.Next()

		// Calculate duration
		duration := time.Since(start)

		// Log details
		log.Printf(
			"Method: %s | Path: %s | Status: %d | Duration: %v | Body: %v",
			c.Method(),
			c.Path(),
			c.Response().StatusCode(),
			duration,
			body,
		)

		return err
	}
}
