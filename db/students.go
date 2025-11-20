package db

import (
	"context"
	"sckool/models"
)

func CreateStudent(ctx context.Context, student models.Student) (*models.Student, error) {
	db := GetDB()

	query := `
		INSERT INTO auth.student (teacher_id, first_name, last_name, middle_name, total_lessons, 
			remaining_lessons, paid_amount, missed_classes, is_paid, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW(), NOW())
		RETURNING id, teacher_id, first_name, last_name, middle_name, total_lessons, 
			remaining_lessons, paid_amount, missed_classes, is_paid, created_at, updated_at
	`

	var result models.Student

	err := db.QueryRowxContext(ctx, query,
		student.TeacherID,
		student.FirstName,
		student.LastName,
		student.MiddleName,
		student.TotalLessons,
		student.RemainingLessons,
		student.PaidAmount,
		student.MissedClasses,
		student.IsPaid,
	).StructScan(&result)

	if err != nil {
		return nil, err
	}

	return &result, nil
}

func GetStudent(ctx context.Context, teacherID int) ([]models.Student, error) {
	db := GetDB()

	query := `SELECT * FROM auth.student WHERE teacher_id = $1 AND deleted_at IS NULL ORDER BY created_at DESC`

	var result []models.Student

	err := db.SelectContext(ctx, &result, query, teacherID)
	if err != nil {
		return nil, err
	}

	return result, nil
}

func GetStudentForId(ctx context.Context, id int, teacherID int) (*models.Student, error) {
	db := GetDB()

	query := `SELECT * FROM auth.student WHERE id = $1 AND teacher_id = $2 AND deleted_at IS NULL`

	var result models.Student

	err := db.GetContext(ctx, &result, query, id, teacherID)
	if err != nil {
		return nil, err
	}

	return &result, nil
}

func DeleteStudent(ctx context.Context, id int, teacherID int) error {
	db := GetDB()

	query := `UPDATE auth.student SET deleted_at = NOW() WHERE id = $1 AND teacher_id = $2 AND deleted_at IS NULL`

	_, err := db.ExecContext(ctx, query, id, teacherID)
	if err != nil {
		return err
	}

	return nil
}

func UpdateStudent(ctx context.Context, id int, teacherID int, student models.Student) (*models.Student, error) {
	db := GetDB()

	query := `
		UPDATE auth.student 
		SET first_name = $1, last_name = $2, middle_name = $3, total_lessons = $4, 
			remaining_lessons = $5, paid_amount = $6, missed_classes = $7, is_paid = $8, 
			updated_at = NOW() 
		WHERE id = $9 AND teacher_id = $10 AND deleted_at IS NULL
		RETURNING id, teacher_id, first_name, last_name, middle_name, total_lessons, 
			remaining_lessons, paid_amount, missed_classes, is_paid, created_at, updated_at
	`

	var result models.Student

	err := db.QueryRowxContext(ctx, query,
		student.FirstName,
		student.LastName,
		student.MiddleName,
		student.TotalLessons,
		student.RemainingLessons,
		student.PaidAmount,
		student.MissedClasses,
		student.IsPaid,
		id,
		teacherID,
	).StructScan(&result)
	if err != nil {
		return nil, err
	}

	return &result, nil
}

func CompleteLesson(ctx context.Context, lesson, id, paid, teacherID int, isPaid bool) error {
	db := GetDB()
	query := `UPDATE auth.student 
		SET remaining_lessons = $1, paid_amount = $2, is_paid = $3, updated_at = NOW() 
		WHERE id = $4 AND teacher_id = $5 AND deleted_at IS NULL`

	_, err := db.ExecContext(ctx, query, lesson, paid, isPaid, id, teacherID)
	if err != nil {
		return err
	}

	return nil
}

func MarkMissed(ctx context.Context, id int, missedCount int, teacherID int) error {
	db := GetDB()
	query := `UPDATE auth.student SET missed_classes = $1, updated_at = NOW() WHERE id = $2 AND teacher_id = $3 AND deleted_at IS NULL`

	_, err := db.ExecContext(ctx, query, missedCount, id, teacherID)
	if err != nil {
		return err
	}

	return nil
}
