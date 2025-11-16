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
	if err := godotenv.Load(); err != nil {
		log.Fatal("Error loading .env file:", err)
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
