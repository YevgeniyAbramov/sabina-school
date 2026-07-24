package handler

import (
	"strconv"

	"sckool/middleware"
	"sckool/models"
	"sckool/service"

	"github.com/gofiber/fiber/v2"
)

type StudentPieceHandler struct {
	service *service.StudentPieceService
}

func NewStudentPieceHandler(service *service.StudentPieceService) *StudentPieceHandler {
	return &StudentPieceHandler{service: service}
}

func (h *StudentPieceHandler) parseStudentID(c *fiber.Ctx) (int, error) {
	return strconv.Atoi(c.Params("id"))
}

func (h *StudentPieceHandler) parsePieceID(c *fiber.Ctx) (int, error) {
	return strconv.Atoi(c.Params("pieceId"))
}

func (h *StudentPieceHandler) List(c *fiber.Ctx) error {
	teacherID := middleware.GetTeacherID(c)
	studentID, err := h.parseStudentID(c)
	if err != nil {
		return c.JSON(fiber.Map{"status": false, "message": "Некорректный id ученика"})
	}
	data, err := h.service.List(c.Context(), studentID, teacherID)
	if err != nil {
		return c.JSON(fiber.Map{"status": false, "message": err.Error()})
	}
	return c.JSON(fiber.Map{"status": true, "message": "Произведения получены", "data": data})
}

func (h *StudentPieceHandler) Get(c *fiber.Ctx) error {
	teacherID := middleware.GetTeacherID(c)
	studentID, err := h.parseStudentID(c)
	if err != nil {
		return c.JSON(fiber.Map{"status": false, "message": "Некорректный id ученика"})
	}
	pieceID, err := h.parsePieceID(c)
	if err != nil {
		return c.JSON(fiber.Map{"status": false, "message": "Некорректный id произведения"})
	}
	data, err := h.service.GetDetail(c.Context(), pieceID, studentID, teacherID)
	if err != nil {
		return c.JSON(fiber.Map{"status": false, "message": err.Error()})
	}
	return c.JSON(fiber.Map{"status": true, "message": "Произведение получено", "data": data})
}

func (h *StudentPieceHandler) Create(c *fiber.Ctx) error {
	teacherID := middleware.GetTeacherID(c)
	studentID, err := h.parseStudentID(c)
	if err != nil {
		return c.JSON(fiber.Map{"status": false, "message": "Некорректный id ученика"})
	}
	var input models.PieceInput
	if err := c.BodyParser(&input); err != nil {
		return c.JSON(fiber.Map{"status": false, "message": "Ошибка разбора тела запроса"})
	}
	data, err := h.service.Create(c.Context(), studentID, teacherID, input)
	if err != nil {
		return c.JSON(fiber.Map{"status": false, "message": err.Error()})
	}
	return c.JSON(fiber.Map{"status": true, "message": "Произведение добавлено", "data": data})
}

func (h *StudentPieceHandler) Update(c *fiber.Ctx) error {
	teacherID := middleware.GetTeacherID(c)
	studentID, err := h.parseStudentID(c)
	if err != nil {
		return c.JSON(fiber.Map{"status": false, "message": "Некорректный id ученика"})
	}
	pieceID, err := h.parsePieceID(c)
	if err != nil {
		return c.JSON(fiber.Map{"status": false, "message": "Некорректный id произведения"})
	}
	var input models.PieceInput
	if err := c.BodyParser(&input); err != nil {
		return c.JSON(fiber.Map{"status": false, "message": "Ошибка разбора тела запроса"})
	}
	data, err := h.service.Update(c.Context(), pieceID, studentID, teacherID, input)
	if err != nil {
		return c.JSON(fiber.Map{"status": false, "message": err.Error()})
	}
	return c.JSON(fiber.Map{"status": true, "message": "Произведение обновлено", "data": data})
}

func (h *StudentPieceHandler) Delete(c *fiber.Ctx) error {
	teacherID := middleware.GetTeacherID(c)
	studentID, err := h.parseStudentID(c)
	if err != nil {
		return c.JSON(fiber.Map{"status": false, "message": "Некорректный id ученика"})
	}
	pieceID, err := h.parsePieceID(c)
	if err != nil {
		return c.JSON(fiber.Map{"status": false, "message": "Некорректный id произведения"})
	}
	if err := h.service.Delete(c.Context(), pieceID, studentID, teacherID); err != nil {
		return c.JSON(fiber.Map{"status": false, "message": err.Error()})
	}
	return c.JSON(fiber.Map{"status": true, "message": "Произведение удалено"})
}

func (h *StudentPieceHandler) AddNote(c *fiber.Ctx) error {
	teacherID := middleware.GetTeacherID(c)
	studentID, err := h.parseStudentID(c)
	if err != nil {
		return c.JSON(fiber.Map{"status": false, "message": "Некорректный id ученика"})
	}
	pieceID, err := h.parsePieceID(c)
	if err != nil {
		return c.JSON(fiber.Map{"status": false, "message": "Некорректный id произведения"})
	}
	var input models.PieceNoteInput
	if err := c.BodyParser(&input); err != nil {
		return c.JSON(fiber.Map{"status": false, "message": "Ошибка разбора тела запроса"})
	}
	data, err := h.service.AddNote(c.Context(), pieceID, studentID, teacherID, input)
	if err != nil {
		return c.JSON(fiber.Map{"status": false, "message": err.Error()})
	}
	return c.JSON(fiber.Map{"status": true, "message": "Заметка добавлена", "data": data})
}

func (h *StudentPieceHandler) DeleteNote(c *fiber.Ctx) error {
	teacherID := middleware.GetTeacherID(c)
	studentID, err := h.parseStudentID(c)
	if err != nil {
		return c.JSON(fiber.Map{"status": false, "message": "Некорректный id ученика"})
	}
	pieceID, err := h.parsePieceID(c)
	if err != nil {
		return c.JSON(fiber.Map{"status": false, "message": "Некорректный id произведения"})
	}
	noteID, err := strconv.Atoi(c.Params("noteId"))
	if err != nil {
		return c.JSON(fiber.Map{"status": false, "message": "Некорректный id заметки"})
	}
	if err := h.service.DeleteNote(c.Context(), noteID, pieceID, studentID, teacherID); err != nil {
		return c.JSON(fiber.Map{"status": false, "message": err.Error()})
	}
	return c.JSON(fiber.Map{"status": true, "message": "Заметка удалена"})
}
