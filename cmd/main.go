package main

import (
	"log"
	"os"
	"path/filepath"
	"context"
	"sckool/auth"
	"sckool/db"
	handler "sckool/handlers"
	eslogger "sckool/logger"
	"sckool/routes"
	"sckool/service"

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

	database, err := db.InitDB()
	if err != nil {
		log.Fatal("Failed to connect to database:", err)
	}

	defer database.Close()

	repos := db.NewRepositories(database)
	services := service.NewServices(repos)
	handlers := handler.NewHandlers(services)

	if err := services.Activity.EnsureSchema(context.Background()); err != nil {
		log.Printf("Warning: activity schema: %v", err)
	}

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

	// API сначала — не перехватывается статикой
	routes.Use(app, handlers.Student, handlers.Auth, handlers.MonthlySummary, handlers.StudentSchedule, handlers.Activity)

	webRoot := resolveWebRoot()
	indexHTML := filepath.Join(webRoot, "index.html")
	log.Printf("Serving frontend from %s", webRoot)

	app.Static("/", webRoot, fiber.Static{
		Index: "index.html",
	})

	// SPA fallback: клиентские маршруты (/login и т.д.)
	app.Get("/*", func(c *fiber.Ctx) error {
		return c.SendFile(indexHTML)
	})

	log.Fatal(app.Listen(":" + port))
}

func resolveWebRoot() string {
	if v := os.Getenv("WEB_ROOT"); v != "" {
		return v
	}
	candidates := []string{"./web2/dist", "./public"}
	for _, dir := range candidates {
		if _, err := os.Stat(filepath.Join(dir, "index.html")); err == nil {
			return dir
		}
	}
	log.Println("Warning: web2/dist not found, falling back to ./public")
	return "./public"
}
