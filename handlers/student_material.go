package handler

import (
	"fmt"
	"os"
	"path/filepath"
	"strconv"
	"strings"

	"sckool/middleware"
	"sckool/models"
	"sckool/service"

	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
)

// Файлы (ноты/сканы) лежат в UPLOAD_ROOT (в проде — смонтированный volume, чтобы
// пережить пересборку контейнера), тот же корень, что раздаётся как /uploads в main.go.
var materialUploadDir = filepath.Join(uploadRoot(), "materials")

const materialURLPrefix = "/uploads/materials"

func uploadRoot() string {
	if v := os.Getenv("UPLOAD_ROOT"); v != "" {
		return v
	}
	return "./uploads"
}

type StudentMaterialHandler struct {
	service *service.StudentMaterialService
}

func NewStudentMaterialHandler(service *service.StudentMaterialService) *StudentMaterialHandler {
	return &StudentMaterialHandler{service: service}
}

func (h *StudentMaterialHandler) parseStudentID(c *fiber.Ctx) (int, error) {
	return strconv.Atoi(c.Params("id"))
}

func (h *StudentMaterialHandler) List(c *fiber.Ctx) error {
	teacherID := middleware.GetTeacherID(c)
	studentID, err := h.parseStudentID(c)
	if err != nil {
		return c.JSON(fiber.Map{"status": false, "message": "Некорректный id ученика"})
	}

	data, err := h.service.ListByStudent(c.Context(), studentID, teacherID)
	if err != nil {
		return c.JSON(fiber.Map{"status": false, "message": err.Error()})
	}
	return c.JSON(fiber.Map{"status": true, "message": "Программа получена", "data": data})
}

func (h *StudentMaterialHandler) CreateLink(c *fiber.Ctx) error {
	teacherID := middleware.GetTeacherID(c)
	studentID, err := h.parseStudentID(c)
	if err != nil {
		return c.JSON(fiber.Map{"status": false, "message": "Некорректный id ученика"})
	}

	var input models.MaterialLinkInput
	if err := c.BodyParser(&input); err != nil {
		return c.JSON(fiber.Map{"status": false, "message": "Ошибка разбора тела запроса"})
	}

	data, err := h.service.CreateLink(c.Context(), studentID, teacherID, input)
	if err != nil {
		return c.JSON(fiber.Map{"status": false, "message": err.Error()})
	}
	return c.JSON(fiber.Map{"status": true, "message": "Ссылка добавлена", "data": data})
}

func (h *StudentMaterialHandler) CreateFile(c *fiber.Ctx) error {
	teacherID := middleware.GetTeacherID(c)
	studentID, err := h.parseStudentID(c)
	if err != nil {
		return c.JSON(fiber.Map{"status": false, "message": "Некорректный id ученика"})
	}

	fileHeader, err := c.FormFile("file")
	if err != nil {
		return c.JSON(fiber.Map{"status": false, "message": "Файл обязателен"})
	}
	if fileHeader.Size > service.MaxMaterialFileSize() {
		return c.JSON(fiber.Map{"status": false, "message": "Файл слишком большой (максимум 20 МБ)"})
	}

	ext := strings.ToLower(filepath.Ext(fileHeader.Filename))
	if !service.IsAllowedMaterialFileExt(ext) {
		return c.JSON(fiber.Map{"status": false, "message": "Разрешены только PDF, PNG, JPG и HEIC"})
	}

	studentDir := filepath.Join(materialUploadDir, strconv.Itoa(teacherID), strconv.Itoa(studentID))
	if err := os.MkdirAll(studentDir, 0o755); err != nil {
		return c.JSON(fiber.Map{"status": false, "message": "Не удалось сохранить файл"})
	}

	storedName := fmt.Sprintf("%s%s", uuid.NewString(), ext)
	diskPath := filepath.Join(studentDir, storedName)
	if err := c.SaveFile(fileHeader, diskPath); err != nil {
		return c.JSON(fiber.Map{"status": false, "message": "Не удалось сохранить файл"})
	}

	fileURL := fmt.Sprintf("%s/%d/%d/%s", materialURLPrefix, teacherID, studentID, storedName)
	title := c.FormValue("title")
	note := c.FormValue("note")

	data, err := h.service.CreateFile(c.Context(), studentID, teacherID, title, note, fileURL, fileHeader.Filename)
	if err != nil {
		_ = os.Remove(diskPath)
		return c.JSON(fiber.Map{"status": false, "message": err.Error()})
	}
	return c.JSON(fiber.Map{"status": true, "message": "Файл добавлен", "data": data})
}

func (h *StudentMaterialHandler) Update(c *fiber.Ctx) error {
	teacherID := middleware.GetTeacherID(c)
	studentID, err := h.parseStudentID(c)
	if err != nil {
		return c.JSON(fiber.Map{"status": false, "message": "Некорректный id ученика"})
	}
	materialID, err := strconv.Atoi(c.Params("materialId"))
	if err != nil {
		return c.JSON(fiber.Map{"status": false, "message": "Некорректный id материала"})
	}

	var input models.MaterialUpdateInput
	if err := c.BodyParser(&input); err != nil {
		return c.JSON(fiber.Map{"status": false, "message": "Ошибка разбора тела запроса"})
	}

	data, err := h.service.Update(c.Context(), materialID, studentID, teacherID, input)
	if err != nil {
		return c.JSON(fiber.Map{"status": false, "message": err.Error()})
	}
	return c.JSON(fiber.Map{"status": true, "message": "Материал обновлён", "data": data})
}

func (h *StudentMaterialHandler) Delete(c *fiber.Ctx) error {
	teacherID := middleware.GetTeacherID(c)
	studentID, err := h.parseStudentID(c)
	if err != nil {
		return c.JSON(fiber.Map{"status": false, "message": "Некорректный id ученика"})
	}
	materialID, err := strconv.Atoi(c.Params("materialId"))
	if err != nil {
		return c.JSON(fiber.Map{"status": false, "message": "Некорректный id материала"})
	}

	deleted, err := h.service.Delete(c.Context(), materialID, studentID, teacherID)
	if err != nil {
		return c.JSON(fiber.Map{"status": false, "message": err.Error()})
	}

	if deleted.Kind == models.MaterialKindFile && strings.HasPrefix(deleted.URL, materialURLPrefix) {
		relative := strings.TrimPrefix(deleted.URL, materialURLPrefix+"/")
		_ = os.Remove(filepath.Join(materialUploadDir, relative))
	}

	return c.JSON(fiber.Map{"status": true, "message": "Материал удалён"})
}
