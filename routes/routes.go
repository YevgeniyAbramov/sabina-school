package routes

import (
	handler "sckool/handlers"
	"sckool/middleware"

	"github.com/gofiber/fiber/v2"
)

func Use(app *fiber.App,
	studentHandler *handler.StudentHandler,
	authHandler *handler.AuthHandler,
	monthlySummaryHandler *handler.MonthlySummaryHandler,
	scheduleHandler *handler.StudentScheduleHandler,
	activityHandler *handler.ActivityHandler,
	materialHandler *handler.StudentMaterialHandler,
	pieceHandler *handler.StudentPieceHandler,
	diaryShareHandler *handler.DiaryShareHandler) {

	app.Get("/status", handler.CheckStatus)

	// Public parent page (no auth) — must be registered before SPA static.
	app.Get("/share/diary/:token", diaryShareHandler.PublicPage)

	api := app.Group("/api/v1/")
	api.Post("/auth/login", authHandler.Login)
	api.Get("/public/diary/:token", diaryShareHandler.PublicJSON)

	protected := api.Group("/", middleware.AuthRequired())

	protected.Post("/students", studentHandler.CreateStudent)
	protected.Get("/students", studentHandler.GetStudents)
	protected.Get("/student/:id", studentHandler.GetStudent)
	protected.Delete("/student/:id", studentHandler.DeleteStudent)
	protected.Put("/student/:id", studentHandler.UpdateStudent)
	protected.Post("/student/:id/complete-lesson", studentHandler.CompleteLesson)
	protected.Post("/student/:id/mark-missed", studentHandler.MarkMissed)

	protected.Get("/student/:id/schedule", scheduleHandler.GetByStudentID)
	protected.Put("/student/:id/schedule", scheduleHandler.ReplaceForStudent)
	protected.Get("/schedule", scheduleHandler.GetByTeacherAndDay)

	protected.Get("/monthly-summary", monthlySummaryHandler.GetMonthlySummary)
	protected.Get("/activity", activityHandler.List)

	protected.Get("/student/:id/materials", materialHandler.List)
	protected.Post("/student/:id/materials/link", materialHandler.CreateLink)
	protected.Post("/student/:id/materials/file", materialHandler.CreateFile)
	protected.Put("/student/:id/materials/:materialId", materialHandler.Update)
	protected.Delete("/student/:id/materials/:materialId", materialHandler.Delete)

	protected.Get("/student/:id/pieces", pieceHandler.List)
	protected.Post("/student/:id/pieces", pieceHandler.Create)
	protected.Get("/student/:id/pieces/:pieceId", pieceHandler.Get)
	protected.Put("/student/:id/pieces/:pieceId", pieceHandler.Update)
	protected.Delete("/student/:id/pieces/:pieceId", pieceHandler.Delete)
	protected.Post("/student/:id/pieces/:pieceId/notes", pieceHandler.AddNote)
	protected.Delete("/student/:id/pieces/:pieceId/notes/:noteId", pieceHandler.DeleteNote)

	protected.Post("/student/:id/diary-share", diaryShareHandler.Create)
}
