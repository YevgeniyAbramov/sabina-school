package db

import (
	"context"
	"sckool/models"
)

type StudentScheduleRepository interface {
	GetByStudentID(ctx context.Context, studentID, teacherID int) ([]models.ScheduleSlot, error)
	GetByTeacherAndDay(ctx context.Context, teacherID int, dayOfWeek int) ([]models.ScheduleSlot, error)
	Create(ctx context.Context, slot models.ScheduleSlot) (*models.ScheduleSlot, error)
	DeleteByID(ctx context.Context, id, teacherID int) error
	DeleteByStudentID(ctx context.Context, studentID, teacherID int) error
	ReplaceForStudent(ctx context.Context, studentID, teacherID int, slots []models.ScheduleSlotInput) ([]models.ScheduleSlot, error)
}

type StudentScheduleRepo struct {
	db *Database
}

func NewStudentScheduleRepo(db *Database) *StudentScheduleRepo {
	return &StudentScheduleRepo{db: db}
}

func (r *StudentScheduleRepo) GetByStudentID(ctx context.Context, studentID, teacherID int) ([]models.ScheduleSlot, error) {
	query := `
		SELECT id, student_id, teacher_id, day_of_week, time_slot, created_at, updated_at
		FROM auth.student_schedule
		WHERE student_id = $1 AND teacher_id = $2
		ORDER BY day_of_week, time_slot
	`
	var result []models.ScheduleSlot
	err := r.db.conn.SelectContext(ctx, &result, query, studentID, teacherID)
	return result, err
}

func (r *StudentScheduleRepo) GetByTeacherAndDay(ctx context.Context, teacherID, dayOfWeek int) ([]models.ScheduleSlot, error) {
	query := `
		SELECT ss.id, ss.student_id, ss.teacher_id, ss.day_of_week, ss.time_slot, ss.created_at, ss.updated_at
		FROM auth.student_schedule ss
		JOIN auth.student s ON s.id = ss.student_id AND s.deleted_at IS NULL
		WHERE ss.teacher_id = $1 AND ss.day_of_week = $2
		ORDER BY ss.time_slot
	`
	var result []models.ScheduleSlot
	err := r.db.conn.SelectContext(ctx, &result, query, teacherID, dayOfWeek)
	return result, err
}

func (r *StudentScheduleRepo) Create(ctx context.Context, slot models.ScheduleSlot) (*models.ScheduleSlot, error) {
	query := `
		INSERT INTO auth.student_schedule (student_id, teacher_id, day_of_week, time_slot, created_at, updated_at)
		VALUES ($1, $2, $3, $4, NOW(), NOW())
		RETURNING id, student_id, teacher_id, day_of_week, time_slot, created_at, updated_at
	`
	var result models.ScheduleSlot
	err := r.db.conn.QueryRowxContext(ctx, query,
		slot.StudentID, slot.TeacherID, slot.DayOfWeek, slot.TimeSlot,
	).StructScan(&result)
	return &result, err
}

func (r *StudentScheduleRepo) DeleteByID(ctx context.Context, id, teacherID int) error {
	query := `DELETE FROM auth.student_schedule WHERE id = $1 AND teacher_id = $2`
	_, err := r.db.conn.ExecContext(ctx, query, id, teacherID)
	return err
}

func (r *StudentScheduleRepo) DeleteByStudentID(ctx context.Context, studentID, teacherID int) error {
	query := `DELETE FROM auth.student_schedule WHERE student_id = $1 AND teacher_id = $2`
	_, err := r.db.conn.ExecContext(ctx, query, studentID, teacherID)
	return err
}

func (r *StudentScheduleRepo) ReplaceForStudent(ctx context.Context, studentID, teacherID int, slots []models.ScheduleSlotInput) ([]models.ScheduleSlot, error) {
	tx, err := r.db.conn.BeginTxx(ctx, nil)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback()

	_, err = tx.ExecContext(ctx, `DELETE FROM auth.student_schedule WHERE student_id = $1 AND teacher_id = $2`, studentID, teacherID)
	if err != nil {
		return nil, err
	}

	var result []models.ScheduleSlot
	for _, s := range slots {
		query := `
			INSERT INTO auth.student_schedule (student_id, teacher_id, day_of_week, time_slot, created_at, updated_at)
			VALUES ($1, $2, $3, $4, NOW(), NOW())
			RETURNING id, student_id, teacher_id, day_of_week, time_slot, created_at, updated_at
		`
		var created models.ScheduleSlot
		err := tx.QueryRowxContext(ctx, query, studentID, teacherID, s.DayOfWeek, s.TimeSlot).StructScan(&created)
		if err != nil {
			return nil, err
		}
		result = append(result, created)
	}

	return result, tx.Commit()
}
