export interface Student {
  id: number
  teacher_id: number
  first_name: string
  last_name: string
  middle_name: string | null
  total_lessons: number
  remaining_lessons: number
  paid_amount: number
  missed_classes: number
  is_paid: boolean
  created_at: string
  updated_at: string
  deleted_at: string | null
}

export interface StudentInput {
  first_name: string
  last_name: string
  middle_name: string
  total_lessons: number
  remaining_lessons: number
  paid_amount: number
  missed_classes: number
  is_paid: boolean
}

export interface ScheduleSlot {
  id?: number
  student_id?: number
  teacher_id?: number
  day_of_week: number
  time_slot: string
}

export interface ScheduleSlotInput {
  day_of_week: number
  time_slot: string
}

export interface MonthlySummary {
  id: number
  teacher_id: number
  year: number
  month: number
  total_amount: number
}

export interface ApiResponse<T = unknown> {
  status: boolean
  message?: string
  data?: T
  token?: string
  teacher?: {
    first_name: string
    last_name?: string
  }
}

export type PaymentFilter = 'all' | 'paid' | 'unpaid'
