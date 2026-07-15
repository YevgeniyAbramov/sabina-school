import { apiRequest } from './client'
import type {
  Activity,
  ActivityKind,
  MonthlySummary,
  ScheduleSlot,
  ScheduleSlotInput,
  Student,
  StudentInput,
} from '../types'

export const studentsApi = {
  list: () => apiRequest<Student[]>('/students'),
  get: (id: number) => apiRequest<Student>(`/student/${id}`),
  create: (student: StudentInput) =>
    apiRequest('/students', {
      method: 'POST',
      body: JSON.stringify(student),
    }),
  update: (id: number, student: StudentInput) =>
    apiRequest(`/student/${id}`, {
      method: 'PUT',
      body: JSON.stringify(student),
    }),
  remove: (id: number) =>
    apiRequest(`/student/${id}`, { method: 'DELETE' }),
  completeLesson: (id: number) =>
    apiRequest(`/student/${id}/complete-lesson`, { method: 'POST' }),
  markMissed: (id: number) =>
    apiRequest(`/student/${id}/mark-missed`, { method: 'POST' }),
}

export const scheduleApi = {
  getByStudent: (id: number) =>
    apiRequest<ScheduleSlot[]>(`/student/${id}/schedule`),
  replaceForStudent: (id: number, slots: ScheduleSlotInput[]) =>
    apiRequest(`/student/${id}/schedule`, {
      method: 'PUT',
      body: JSON.stringify({ slots }),
    }),
  getByDay: (day: number) =>
    apiRequest<ScheduleSlot[]>(`/schedule?day=${day}`),
}

export const summaryApi = {
  get: (year: number, month: number) =>
    apiRequest<MonthlySummary>(`/monthly-summary?year=${year}&month=${month}`),
}

export const activityApi = {
  list: (kind: ActivityKind | 'all' = 'all') =>
    apiRequest<Activity[]>(`/activity?kind=${kind}`),
}
