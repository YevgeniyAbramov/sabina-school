package handler

import (
	"sckool/middleware"
	"sckool/service"

	"github.com/gofiber/fiber/v2"
)

type ActivityHandler struct {
	service *service.ActivityService
}

func NewActivityHandler(service *service.ActivityService) *ActivityHandler {
	return &ActivityHandler{service: service}
}

func (h *ActivityHandler) List(c *fiber.Ctx) error {
	teacherID := middleware.GetTeacherID(c)
	kind := c.Query("kind", "all")

	data, err := h.service.List(c.Context(), teacherID, kind)
	if err != nil {
		return c.JSON(fiber.Map{
			"status":  false,
			"message": "Не удалось загрузить историю: " + err.Error(),
		})
	}

	return c.JSON(fiber.Map{
		"status": true,
		"data":   data,
	})
}
