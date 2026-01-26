package logger

import (
	"bytes"
	"context"
	"encoding/json"
	"log"
	"time"

	"github.com/elastic/go-elasticsearch/v8"
	"github.com/elastic/go-elasticsearch/v8/esapi"
)

type LogEntry struct {
	Timestamp time.Time `json:"@timestamp"`
	Action    string    `json:"action"`
	TeacherID int       `json:"teacher_id"`
	StudentID *int      `json:"student_id,omitempty"`
	Status    string    `json:"status"`
	Message   string    `json:"message"`
	Error     string    `json:"error,omitempty"`
}

type ElasticLogger struct {
	client *elasticsearch.Client
}

var globalLogger *ElasticLogger

func NewElasticLogger(url string) (*ElasticLogger, error) {
	cfg := elasticsearch.Config{
		Addresses: []string{url},
	}
	client, err := elasticsearch.NewClient(cfg)
	if err != nil {
		return nil, err
	}

	res, err := client.Info()
	if err != nil {
		return nil, err
	}
	res.Body.Close()

	logger := &ElasticLogger{client: client}
	globalLogger = logger

	log.Println("Elasticsearch connected")
	return logger, nil
}

func (el *ElasticLogger) Log(action string, teacherID int, studentID *int, status string, message string) {
	entry := LogEntry{
		Timestamp: time.Now(),
		Action:    action,
		TeacherID: teacherID,
		StudentID: studentID,
		Status:    status,
		Message:   message,
	}

	jsonData, _ := json.Marshal(entry)
	req := esapi.IndexRequest{
		Index: "sckool-logs",
		Body:  bytes.NewReader(jsonData),
	}

	res, err := req.Do(context.Background(), el.client)
	if err != nil {
		log.Printf("ES error: %v", err)
		return
	}

	defer res.Body.Close()
}

func Log(action string, teacherID int, studentID *int, status string, message string) {
	if globalLogger != nil {
		globalLogger.Log(action, teacherID, studentID, status, message)
	}
}

func (el *ElasticLogger) Close() {
	log.Println("Logger closed")
}
