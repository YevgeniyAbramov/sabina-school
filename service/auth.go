package service

import (
	"context"
	"errors"
	"sckool/auth"
	"sckool/db"
	"sckool/logger"
	"sckool/models"
)

type AuthService struct {
	teacherRepo db.TeacherRepository
}

func NewAuthService(teacherRepo db.TeacherRepository) *AuthService {
	return &AuthService{teacherRepo: teacherRepo}
}

func (s *AuthService) Login(ctx context.Context, username, password string) (*models.Teacher, string, error) {
	teacher, err := s.teacherRepo.GetTeacherByLogin(ctx, username)
	if err != nil {
		return nil, "", errors.New("неверный логин или пароль")
	}

	if teacher.Password != password {
		return nil, "", errors.New("неверный логин или пароль")
	}

	go logger.Log("login", teacher.Id, nil, "success", "Вход выполнен")

	token, err := auth.GenerateToken(teacher.Id)
	if err != nil {
		return nil, "", errors.New("ошибка генерации токена")
	}

	return teacher, token, nil
}
