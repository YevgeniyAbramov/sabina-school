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

	if resp.RemainingLessons == 0 {
		return errors.New("количество уроков истекло")
	}

	newRemaining := resp.RemainingLessons - 1
	if newRemaining < 0 {
		newRemaining = 0
	}

	newPaidAmount := resp.PaidAmount
	if newRemaining == 0 {
		newPaidAmount = 0
	} else if resp.RemainingLessons > 0 {
		lessonPrice := resp.PaidAmount / resp.RemainingLessons
		newPaidAmount = resp.PaidAmount - lessonPrice
	}

	newIsPaid := resp.IsPaid
	if newRemaining == 0 {
		newIsPaid = false
	}

	err = db.CompleteLesson(ctx, newRemaining, id, newPaidAmount, teacherID, newIsPaid)
	if err != nil {
		return err
	}

	return nil
}

func MarkMissed(ctx context.Context, id int, teacherID int) error {
	student, err := db.GetStudentForId(ctx, id, teacherID)
	if err != nil {
		return err
	}

	newMissedCount := student.MissedClasses + 1

	err = db.MarkMissed(ctx, id, newMissedCount, teacherID)
	if err != nil {
		return err
	}

	return nil
}
