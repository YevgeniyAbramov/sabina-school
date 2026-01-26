package db

import (
	"context"
	"sckool/models"
)

func GetTeacherByLogin(ctx context.Context, login string) (*models.Teacher, error) {
	db := GetDB()

	query := `SELECT id, login, password, first_name, last_name, middle_name, created_at, updated_at 
	          FROM auth.teacher 
	          WHERE login = $1 AND deleted_at IS NULL`

	var teacher models.Teacher
	err := db.GetContext(ctx, &teacher, query, login)
	if err != nil {
		return nil, err
	}

	return &teacher, nil
}

func GetTeacherByID(ctx context.Context, id int) (*models.Teacher, error) {
	db := GetDB()

	query := `SELECT id, login, first_name, last_name, middle_name, created_at, updated_at 
	          FROM auth.teacher 
	          WHERE id = $1 AND deleted_at IS NULL`

	var teacher models.Teacher
	err := db.GetContext(ctx, &teacher, query, id)
	if err != nil {
		return nil, err
	}

	return &teacher, nil
}
