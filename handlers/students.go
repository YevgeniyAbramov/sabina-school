package handler

import (
	"sckool/middleware"
	"sckool/models"
	"sckool/service"
	"strconv"

	"github.com/gofiber/fiber/v2"
)

func CreateStudent(c *fiber.Ctx) error {
	teacherID := middleware.GetTeacherID(c)

	var req models.Student
	err := c.BodyParser(&req)
	if err != nil {
		return c.JSON(fiber.Map{
			"status":  false,
			"message": "Error BodyParser " + err.Error(),
		})
	}

	req.TeacherID = teacherID

	resp, err := service.CreateStudent(c.Context(), req)
	if err != nil {
		return c.JSON(fiber.Map{
			"status":  false,
			"message": "Error Create student" + err.Error(),
		})
	}

	return c.JSON(fiber.Map{
		"status":  true,
		"message": "Student Create",
		"data":    resp,
	})
}

func GetStudents(c *fiber.Ctx) error {
	teacherID := middleware.GetTeacherID(c)
	param := c.Query("is_paid")

	var isPaid *bool
	if param != "" {
		paramBool, err := strconv.ParseBool(param)
		if err != nil {
			return c.JSON(fiber.Map{
				"status":  false,
				"message": "Error ParseBool" + err.Error(),
			})
		}
		isPaid = &paramBool
	}

	resp, err := service.GetStudent(c.Context(), teacherID, isPaid)
	if err != nil {
		return c.JSON(fiber.Map{
			"status":  false,
			"message": "Error Get student" + err.Error(),
		})
	}
	return c.JSON(fiber.Map{
		"status":  true,
		"message": "Get all students",
		"data":    resp,
	})
}

func GetStudent(c *fiber.Ctx) error {
	teacherID := middleware.GetTeacherID(c)

	idParam := c.Params("id")
	id, err := strconv.Atoi(idParam)
	if err != nil {
		return c.JSON(fiber.Map{
			"status":  false,
			"message": "Error convert to int" + err.Error(),
		})
	}

	resp, err := service.GetStudentForId(c.Context(), id, teacherID)
	if err != nil {
		return c.JSON(fiber.Map{
			"status":  false,
			"message": "Error Get student" + err.Error(),
		})
	}
	return c.JSON(fiber.Map{
		"status":  true,
		"message": "Get student by id",
		"data":    resp,
	})
}

func DeleteStudent(c *fiber.Ctx) error {
	teacherID := middleware.GetTeacherID(c)

	idParam := c.Params("id")
	id, err := strconv.Atoi(idParam)
	if err != nil {
		return c.JSON(fiber.Map{
			"status":  false,
			"message": "Error convert to int" + err.Error(),
		})
	}

	err = service.DeleteStudent(c.Context(), id, teacherID)
	if err != nil {
		return c.JSON(fiber.Map{
			"status":  false,
			"message": "Error Delete student" + err.Error(),
		})
	}
	return c.JSON(fiber.Map{
		"status":  true,
		"message": "Delete student by id",
	})

}

func UpdateStudent(c *fiber.Ctx) error {
	teacherID := middleware.GetTeacherID(c)

	idParam := c.Params("id")
	id, err := strconv.Atoi(idParam)
	if err != nil {
		return c.JSON(fiber.Map{
			"status":  false,
			"message": "Error convert to int" + err.Error(),
		})
	}

	var req models.Student
	err = c.BodyParser(&req)
	if err != nil {
		return c.JSON(fiber.Map{
			"status":  false,
			"message": "Error BodyParser " + err.Error(),
		})
	}

	resp, err := service.UpdateStudent(c.Context(), id, teacherID, req)
	if err != nil {
		return c.JSON(fiber.Map{
			"status":  false,
			"message": "Error Update student" + err.Error(),
		})
	}
	return c.JSON(fiber.Map{
		"status":  true,
		"message": "Update student by id",
		"data":    resp,
	})
}

func CompleteLesson(c *fiber.Ctx) error {
	teacherID := middleware.GetTeacherID(c)

	idParam := c.Params("id")
	id, err := strconv.Atoi(idParam)
	if err != nil {
		return c.JSON(fiber.Map{
			"status":  false,
			"message": "Error convert to int" + err.Error(),
		})
	}

	err = service.CompleteLesson(c.Context(), id, teacherID)
	if err != nil {
		return c.JSON(fiber.Map{
			"status":  false,
			"message": "Error CompleteLesson student: " + err.Error(),
		})
	}

	return c.JSON(fiber.Map{
		"status":  true,
		"message": "Урок проведен",
	})
}

func MarkMissed(c *fiber.Ctx) error {
	teacherID := middleware.GetTeacherID(c)

	idParam := c.Params("id")
	id, err := strconv.Atoi(idParam)
	if err != nil {
		return c.JSON(fiber.Map{
			"status":  false,
			"message": "Error convert to int" + err.Error(),
		})
	}

	err = service.MarkMissed(c.Context(), id, teacherID)
	if err != nil {
		return c.JSON(fiber.Map{
			"status":  false,
			"message": "Error MarkMissed student: " + err.Error(),
		})
	}

	return c.JSON(fiber.Map{
		"status":  true,
		"message": "Пропуск отмечен",
	})
}
