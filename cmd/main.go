package main

import (
	"log"
	"os"
	"sckool/auth"
	"sckool/db"
	eslogger "sckool/logger"
	"sckool/routes"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/logger"
	"github.com/joho/godotenv"
)

func main() {
	if err := godotenv.Load(); err != nil {
		log.Println("Warning: .env file not found, using environment variables")
	}

	if err := auth.Init(); err != nil {
		log.Fatal("Failed to initialize auth:", err)
	}

	db.InitDB()

	esURL := os.Getenv("ELASTICSEARCH_URL")
	esUsername := os.Getenv("ELASTICSEARCH_USERNAME")
	esPassword := os.Getenv("ELASTICSEARCH_PASSWORD")
	esLogger, err := eslogger.NewElasticLogger(esURL, esUsername, esPassword)
	if err != nil {
		log.Printf("Warning: Elasticsearch not available: %v", err)
	} else {
		defer esLogger.Close()
	}

	port := os.Getenv("port")
	app := fiber.New(fiber.Config{
		ErrorHandler: func(ctx *fiber.Ctx, err error) error {
			code := fiber.StatusInternalServerError

			return ctx.Status(code).JSON(fiber.Map{
				"status":  false,
				"message": err.Error(),
			})
		},
		DisableStartupMessage: false,
	})

	app.Use(logger.New())

	app.Static("/", "./public")

	routes.Use(app)

	log.Fatal(app.Listen(":" + port))
}
