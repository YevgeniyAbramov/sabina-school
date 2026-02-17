package handler

import (
	"sckool/middleware"
	"sckool/service"

	"github.com/gofiber/fiber/v2"
)

type MonthlySummaryHandler struct {
	service *service.MonthlySummaryService
}

func NewMonthlySummaryHandler(service *service.MonthlySummaryService) *MonthlySummaryHandler {
	return &MonthlySummaryHandler{service: service}
}

func (h *MonthlySummaryHandler) GetMonthlySummary(c *fiber.Ctx) error {
	teacherID := middleware.GetTeacherID(c)
	year := c.QueryInt("year")
	month := c.QueryInt("month")

	if year == 0 || month == 0 {
		return c.JSON(fiber.Map{
			"status":  false,
			"message": "Параметры year и month обязательны",
		})
	}

	if month < 1 || month > 12 {
		return c.JSON(fiber.Map{
			"status":  false,
			"message": "Месяц должен быть от 1 до 12",
		})
	}

	data, err := h.service.GetMonthlySummary(c.Context(), teacherID, year, month)
	if err != nil {
		return c.JSON(fiber.Map{
			"status":  false,
			"message": "Месячный итог не найден",
		})
	}

	return c.JSON(fiber.Map{
		"status":  true,
		"message": "Месячный итог получен",
		"data":    data,
	})

}
