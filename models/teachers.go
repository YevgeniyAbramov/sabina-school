package models

import "time"

type Teacher struct {
	Id         int        `json:"id" db:"id"`
	Login      string     `json:"login" db:"login"`
	Password   string     `json:"-" db:"password"`
	FirstName  string     `json:"first_name" db:"first_name"`
	LastName   *string    `json:"last_name" db:"last_name"`
	MiddleName *string    `json:"middle_name" db:"middle_name"`
	CreatedAt  time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt  *time.Time `json:"updated_at" db:"updated_at"`
	DeletedAt  *time.Time `json:"deleted_at" db:"deleted_at"`
}
