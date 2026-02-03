package routes

import (
	handler "sckool/handlers"
	"sckool/middleware"

	"github.com/gofiber/fiber/v2"
)

func Use(app *fiber.App) {
	api := app.Group("/api/v1/")

	// Публичные роуты (без авторизации)
	api.Get("/status", handler.CheckStatus)
	api.Post("/auth/login", handler.Login)

	// Защищенные роуты (требуют токен)
	protected := api.Group("/", middleware.AuthRequired())
	protected.Post("/students", handler.CreateStudent)
	protected.Get("/students", handler.GetStudents)
	protected.Get("/student/:id", handler.GetStudent)
	protected.Delete("/student/:id", handler.DeleteStudent)
	protected.Put("/student/:id", handler.UpdateStudent)
	protected.Post("/student/:id/complete-lesson", handler.CompleteLesson)
	protected.Post("/student/:id/mark-missed", handler.MarkMissed)
	protected.Get("/monthly-summary", handler.GetMonthlySummary)
}
