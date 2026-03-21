package handler

import (
	"sckool/middleware"
	"sckool/models"
	"sckool/service"
	"strconv"

	"github.com/gofiber/fiber/v2"
)

type StudentScheduleHandler struct {
	service *service.StudentScheduleService
}

func NewStudentScheduleHandler(service *service.StudentScheduleService) *StudentScheduleHandler {
	return &StudentScheduleHandler{service: service}
}

func (h *StudentScheduleHandler) GetByStudentID(c *fiber.Ctx) error {
	teacherID := middleware.GetTeacherID(c)
	idParam := c.Params("id")
	id, err := strconv.Atoi(idParam)
	if err != nil {
		return c.JSON(fiber.Map{"status": false, "message": "Некорректный id"})
	}

	data, err := h.service.GetByStudentID(c.Context(), id, teacherID)
	if err != nil {
		return c.JSON(fiber.Map{"status": false, "message": err.Error()})
	}
	return c.JSON(fiber.Map{"status": true, "message": "Расписание получено", "data": data})
}

func (h *StudentScheduleHandler) GetByTeacherAndDay(c *fiber.Ctx) error {
	teacherID := middleware.GetTeacherID(c)
	dayParam := c.Query("day")
	if dayParam == "" {
		return c.JSON(fiber.Map{"status": false, "message": "Параметр day обязателен"})
	}
	day, err := strconv.Atoi(dayParam)
	if err != nil || day < 0 || day > 6 {
		return c.JSON(fiber.Map{"status": false, "message": "day должен быть числом от 0 до 6"})
	}

	data, err := h.service.GetByTeacherAndDay(c.Context(), teacherID, day)
	if err != nil {
		return c.JSON(fiber.Map{"status": false, "message": err.Error()})
	}
	return c.JSON(fiber.Map{"status": true, "message": "Расписание на день получено", "data": data})
}

func (h *StudentScheduleHandler) ReplaceForStudent(c *fiber.Ctx) error {
	teacherID := middleware.GetTeacherID(c)
	idParam := c.Params("id")
	id, err := strconv.Atoi(idParam)
	if err != nil {
		return c.JSON(fiber.Map{"status": false, "message": "Некорректный id"})
	}

	var req models.ScheduleReplaceRequest
	if err := c.BodyParser(&req); err != nil {
		return c.JSON(fiber.Map{"status": false, "message": "Ошибка разбора тела запроса"})
	}
	if req.Slots == nil {
		req.Slots = []models.ScheduleSlotInput{}
	}

	data, err := h.service.ReplaceForStudent(c.Context(), id, teacherID, req.Slots)
	if err != nil {
		return c.JSON(fiber.Map{"status": false, "message": err.Error()})
	}
	return c.JSON(fiber.Map{"status": true, "message": "Расписание обновлено", "data": data})
}
