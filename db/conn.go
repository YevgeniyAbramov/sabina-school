package db

import (
	"fmt"
	"log"
	"os"

	_ "github.com/jackc/pgx/v5/stdlib"

	"github.com/jmoiron/sqlx"
	"github.com/joho/godotenv"
)

var conn *sqlx.DB

func GetDB() *sqlx.DB {
	return conn
}

func InitDB() {
	err := godotenv.Load()
	if err != nil {
		log.Println("Warning: .env file not found in InitDB, using environment variables")
	}
	username := os.Getenv("db_user")
	password := os.Getenv("db_password")
	dbName := os.Getenv("db_name")
	dbHost := os.Getenv("db_host")
	dbPort := os.Getenv("db_port")
	sslmode := os.Getenv("db_sslmode")

	connStr := fmt.Sprintf("host=%s port=%s user=%s dbname=%s password=%s sslmode=%s", dbHost, dbPort, username, dbName, password, sslmode)

	db, err := sqlx.Connect("pgx", connStr)
	if err != nil {
		log.Fatal("error connecting to database:", err)
	}
	log.Println("DB connection is established =)")

	conn = db
}
