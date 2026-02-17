package handler

import (
	"sckool/service"

	"github.com/gofiber/fiber/v2"
)

type AuthHandler struct {
	authService *service.AuthService
}

func NewAuthHandler(authService *service.AuthService) *AuthHandler {
	return &AuthHandler{authService: authService}
}

func (h *AuthHandler) Login(c *fiber.Ctx) error {
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

	teacher, token, err := h.authService.Login(c.Context(), req.Username, req.Password)
	if err != nil {
		return c.Status(401).JSON(fiber.Map{
			"status":  false,
			"message": err.Error(),
		})
	}

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
