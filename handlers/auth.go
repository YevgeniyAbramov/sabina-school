package handler

import (
	"fmt"
	"sckool/db"
	"sckool/logger"

	"github.com/gofiber/fiber/v2"
)

func Login(c *fiber.Ctx) error {
	var req struct {
		Username string `json:"username"`
		Password string `json:"password"`
	}

	if err := c.BodyParser(&req); err != nil {
		return c.JSON(fiber.Map{
			"status":  false,
			"message": "Неверный формат данных",
		})
	}

	if req.Username == "" || req.Password == "" {
		return c.JSON(fiber.Map{
			"status":  false,
			"message": "Логин и пароль обязательны",
		})
	}

	teacher, err := db.GetTeacherByLogin(c.Context(), req.Username)
	if err != nil {
		return c.Status(401).JSON(fiber.Map{
			"status":  false,
			"message": "Неверный логин или пароль",
		})
	}

	if teacher.Password != req.Password {
		return c.Status(401).JSON(fiber.Map{
			"status":  false,
			"message": "Неверный логин или пароль",
		})
	}

	go logger.Log("login", teacher.Id, nil, "success", "Вход выполнен")

	token := fmt.Sprintf("token-%d", teacher.Id)

	return c.JSON(fiber.Map{
		"status":  true,
		"message": "Вход выполнен успешно",
		"token":   token,
		"teacher": fiber.Map{
			"id":         teacher.Id,
			"first_name": teacher.FirstName,
			"last_name":  teacher.LastName,
		},
	})
}
