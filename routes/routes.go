package routes

import (
	handler "sckool/handlers"
	"sckool/middleware"

	"github.com/gofiber/fiber/v2"
)

func Use(app *fiber.App, studentHandler *handler.StudentHandler, authHandler *handler.AuthHandler, monthlySummaryHandler *handler.MonthlySummaryHandler) {

	api := app.Group("/api/v1/")
	// Публичные роуты (без авторизации)
	api.Get("/status", handler.CheckStatus)
	api.Post("/auth/login", authHandler.Login)

	// Защищенные роуты (требуют токен)
	protected := api.Group("/", middleware.AuthRequired())

	protected.Post("/students", studentHandler.CreateStudent)
	protected.Get("/students", studentHandler.GetStudents)
	protected.Get("/student/:id", studentHandler.GetStudent)
	protected.Delete("/student/:id", studentHandler.DeleteStudent)
	protected.Put("/student/:id", studentHandler.UpdateStudent)
	protected.Post("/student/:id/complete-lesson", studentHandler.CompleteLesson)
	protected.Post("/student/:id/mark-missed", studentHandler.MarkMissed)

	protected.Get("/monthly-summary", monthlySummaryHandler.GetMonthlySummary)
}
