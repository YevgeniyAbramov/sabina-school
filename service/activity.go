package service

import (
	"context"
	"fmt"
	"log"
	"sckool/db"
	"sckool/models"
	"strings"
)

type ActivityService struct {
	repo db.ActivityRepository
}

func NewActivityService(repo db.ActivityRepository) *ActivityService {
	return &ActivityService{repo: repo}
}

func (s *ActivityService) EnsureSchema(ctx context.Context) error {
	return s.repo.EnsureSchema(ctx)
}

func (s *ActivityService) List(ctx context.Context, teacherID int, kind string) ([]models.Activity, error) {
	return s.repo.ListByTeacher(ctx, teacherID, kind, 80)
}

func (s *ActivityService) Record(ctx context.Context, a models.Activity) {
	go func() {
		if err := s.repo.Create(context.Background(), a); err != nil {
			log.Printf("activity record error: %v", err)
		}
	}()
}

func StudentDisplayName(st *models.Student) string {
	if st == nil {
		return "ученик"
	}
	parts := []string{st.FirstName}
	if st.LastName != "" {
		parts = append(parts, st.LastName)
	}
	return strings.TrimSpace(strings.Join(parts, " "))
}

func (s *ActivityService) RecordLesson(teacherID int, st *models.Student) {
	id := st.Id
	s.Record(context.Background(), models.Activity{
		TeacherID: teacherID,
		StudentID: &id,
		Kind:      models.ActivityLesson,
		Title:     StudentDisplayName(st),
		Detail:    "Урок проведён",
	})
}

func (s *ActivityService) RecordMissed(teacherID int, st *models.Student) {
	id := st.Id
	s.Record(context.Background(), models.Activity{
		TeacherID: teacherID,
		StudentID: &id,
		Kind:      models.ActivityMissed,
		Title:     StudentDisplayName(st),
		Detail:    "Пропуск",
	})
}

func (s *ActivityService) RecordRenew(teacherID int, st *models.Student, lessons, amount int) {
	id := st.Id
	amt := amount
	s.Record(context.Background(), models.Activity{
		TeacherID: teacherID,
		StudentID: &id,
		Kind:      models.ActivityRenew,
		Title:     StudentDisplayName(st),
		Detail:    fmt.Sprintf("Продление · %d уроков", lessons),
		Amount:    &amt,
	})
}

func (s *ActivityService) RecordPayment(teacherID int, st *models.Student, amount int, detail string) {
	id := st.Id
	amt := amount
	s.Record(context.Background(), models.Activity{
		TeacherID: teacherID,
		StudentID: &id,
		Kind:      models.ActivityPayment,
		Title:     StudentDisplayName(st),
		Detail:    detail,
		Amount:    &amt,
	})
}

func (s *ActivityService) RecordStudentCreated(teacherID int, st *models.Student) {
	id := st.Id
	s.Record(context.Background(), models.Activity{
		TeacherID: teacherID,
		StudentID: &id,
		Kind:      models.ActivityStudent,
		Title:     StudentDisplayName(st),
		Detail:    "Новый ученик",
	})
}
