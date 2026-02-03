package handler

import (
	"sckool/middleware"
	"sckool/service"

	"github.com/gofiber/fiber/v2"
)

func GetMonthlySummary(c *fiber.Ctx) error {
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

	data, err := service.GetMonthlySummary(c.Context(), teacherID, year, month)
	if err != nil {
		return c.JSON(fiber.Map{
			"status":  true,
			"message": "Месячный итог не найден",
			"data": fiber.Map{
				"teacher_id":   teacherID,
				"year":         year,
				"month":        month,
				"total_amount": 0,
			},
		})
	}

	return c.JSON(fiber.Map{
		"status":  true,
		"message": "Месячный итог получен",
		"data":    data,
	})

}
