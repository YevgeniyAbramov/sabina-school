package middleware

import (
	"strconv"
	"strings"

	"github.com/gofiber/fiber/v2"
)

// AuthRequired - простой middleware для проверки токена
func AuthRequired() fiber.Handler {
	return func(c *fiber.Ctx) error {
		// Получаем заголовок Authorization
		authHeader := c.Get("Authorization")

		// Проверяем что заголовок не пустой
		if authHeader == "" {
			return c.Status(401).JSON(fiber.Map{
				"status":  false,
				"message": "Требуется авторизация",
			})
		}

		// Ожидаем формат: "Bearer <token>"
		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			return c.Status(401).JSON(fiber.Map{
				"status":  false,
				"message": "Неверный формат токена",
			})
		}

		token := parts[1]

		// Проверяем что токен не пустой
		if token == "" {
			return c.Status(401).JSON(fiber.Map{
				"status":  false,
				"message": "Токен отсутствует",
			})
		}

		// Парсим токен формата "token-{teacher_id}"
		// Позже здесь будет проверка JWT
		tokenParts := strings.Split(token, "-")
		if len(tokenParts) != 2 || tokenParts[0] != "token" {
			return c.Status(401).JSON(fiber.Map{
				"status":  false,
				"message": "Невалидный формат токена",
			})
		}

		// Извлекаем teacher_id из токена
		teacherID, err := strconv.Atoi(tokenParts[1])
		if err != nil {
			return c.Status(401).JSON(fiber.Map{
				"status":  false,
				"message": "Невалидный токен",
			})
		}

		// Сохраняем токен и teacher_id в контексте
		c.Locals("token", token)
		c.Locals("teacher_id", teacherID)

		// Продолжаем выполнение следующего handler'а
		return c.Next()
	}
}

// GetTeacherID - вспомогательная функция для получения teacher_id в handler'ах
func GetTeacherID(c *fiber.Ctx) int {
	teacherID, ok := c.Locals("teacher_id").(int)
	if !ok {
		return 0
	}
	return teacherID
}
