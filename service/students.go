package service

import (
	"context"
	"errors"
	"sckool/db"
	"sckool/models"
)

func CreateStudent(ctx context.Context, student models.Student) (*models.Student, error) {
	result, err := db.CreateStudent(ctx, student)
	if err != nil {
		return nil, err
	}

	return result, nil
}

func GetStudent(ctx context.Context, teacherID int) ([]models.Student, error) {
	result, err := db.GetStudent(ctx, teacherID)
	if err != nil {
		return nil, err
	}

	return result, err
}

func GetStudentForId(ctx context.Context, id int, teacherID int) (*models.Student, error) {
	result, err := db.GetStudentForId(ctx, id, teacherID)
	if err != nil {
		return nil, err
	}

	return result, err
}

func DeleteStudent(ctx context.Context, id int, teacherID int) error {
	err := db.DeleteStudent(ctx, id, teacherID)
	if err != nil {
		return err
	}

	return nil
}

func UpdateStudent(ctx context.Context, id int, teacherID int, student models.Student) (*models.Student, error) {
	result, err := db.UpdateStudent(ctx, id, teacherID, student)
	if err != nil {
		return nil, err
	}
	return result, nil
}

func CompleteLesson(ctx context.Context, id int, teacherID int) error {
	resp, err := db.GetStudentForId(ctx, id, teacherID)
	if err != nil {
		return err
	}

	var lesson int
	var PeidAmountLast int

	if resp.RemainingLessons == 0 {
		return errors.New("количетсво уроков истякло")
	}

	lesson = resp.RemainingLessons - 1

	// Если это последний урок - обнуляем баланс
	if lesson == 0 {
		PeidAmountLast = 0
	} else {
		// Рассчитываем стоимость одного урока: текущий баланс / оставшиеся уроки
		lessonPrice := resp.PaidAmount / resp.RemainingLessons
		// Вычитаем стоимость урока из оплаченной суммы
		PeidAmountLast = resp.PaidAmount - lessonPrice
	}

	err = db.CompleteLesson(ctx, lesson, id, PeidAmountLast, teacherID)
	if err != nil {
		return err
	}

	return nil
}

func MarkMissed(ctx context.Context, id int, teacherID int) error {
	// Получаем данные студента
	student, err := db.GetStudentForId(ctx, id, teacherID)
	if err != nil {
		return err
	}

	// Увеличиваем счетчик пропусков
	newMissedCount := student.MissedClasses + 1

	// Обновляем в БД
	err = db.MarkMissed(ctx, id, newMissedCount, teacherID)
	if err != nil {
		return err
	}

	return nil
}
