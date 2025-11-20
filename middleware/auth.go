package middleware

import (
	"strconv"
	"strings"

	"github.com/gofiber/fiber/v2"
)

func AuthRequired() fiber.Handler {
	return func(c *fiber.Ctx) error {
		authHeader := c.Get("Authorization")

		if authHeader == "" {
			return c.Status(401).JSON(fiber.Map{
				"status":  false,
				"message": "Требуется авторизация",
			})
		}

		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			return c.Status(401).JSON(fiber.Map{
				"status":  false,
				"message": "Неверный формат токена",
			})
		}

		token := parts[1]

		if token == "" {
			return c.Status(401).JSON(fiber.Map{
				"status":  false,
				"message": "Токен отсутствует",
			})
		}

		tokenParts := strings.Split(token, "-")
		if len(tokenParts) != 2 || tokenParts[0] != "token" {
			return c.Status(401).JSON(fiber.Map{
				"status":  false,
				"message": "Невалидный формат токена",
			})
		}

		teacherID, err := strconv.Atoi(tokenParts[1])
		if err != nil {
			return c.Status(401).JSON(fiber.Map{
				"status":  false,
				"message": "Невалидный токен",
			})
		}

		c.Locals("token", token)
		c.Locals("teacher_id", teacherID)

		return c.Next()
	}
}

func GetTeacherID(c *fiber.Ctx) int {
	teacherID, ok := c.Locals("teacher_id").(int)
	if !ok {
		return 0
	}
	return teacherID
}
