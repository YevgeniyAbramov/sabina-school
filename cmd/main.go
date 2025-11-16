package main

import (
	"log"
	"os"
	"sckool/db"
	"sckool/routes"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/logger"
	"github.com/joho/godotenv"
)

func main() {
	// Пытаемся загрузить .env, но не падаем если его нет
	// В Docker используются переменные окружения из docker-compose
	if err := godotenv.Load(); err != nil {
		log.Println("Warning: .env file not found, using environment variables")
	}

	db.InitDB()

	port := os.Getenv("port")

	app := fiber.New(fiber.Config{
		ErrorHandler: func(ctx *fiber.Ctx, err error) error {
			// StatusCode defaults to 500
			code := fiber.StatusInternalServerError

			return ctx.Status(code).JSON(fiber.Map{
				"status":  false,
				"message": err.Error(),
			})
		},
		DisableStartupMessage: false,
	})

	app.Use(logger.New())

	// Отдача статических файлов (HTML, JS, CSS)
	app.Static("/", "./public")

	routes.Use(app)

	log.Fatal(app.Listen(":" + port))
}
