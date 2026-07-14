import type { ApiResponse } from '../types'

const API_URL = '/api/v1'

export class AuthError extends Error {
  constructor(message = 'Unauthorized') {
    super(message)
    this.name = 'AuthError'
  }
}

export function getToken(): string | null {
  return localStorage.getItem('auth_token')
}

export function getTeacherName(): string | null {
  return localStorage.getItem('teacher_name')
}

export function setAuth(token: string, teacherName?: string) {
  localStorage.setItem('auth_token', token)
  if (teacherName) {
    localStorage.setItem('teacher_name', teacherName)
  }
}

export function clearAuth() {
  localStorage.removeItem('auth_token')
  localStorage.removeItem('teacher_name')
}

function authHeaders(): HeadersInit {
  const token = getToken()
  return {
    'Content-Type': 'application/json',
    ...(token ? { Authorization: `Bearer ${token}` } : {}),
  }
}

export async function apiRequest<T = unknown>(
  path: string,
  options: RequestInit = {},
): Promise<ApiResponse<T>> {
  const response = await fetch(`${API_URL}${path}`, {
    ...options,
    headers: {
      ...authHeaders(),
      ...options.headers,
    },
  })

  if (response.status === 401) {
    clearAuth()
    throw new AuthError()
  }

  return response.json() as Promise<ApiResponse<T>>
}

export async function login(username: string, password: string) {
  const response = await fetch(`${API_URL}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username, password }),
  })
  return response.json() as Promise<ApiResponse>
}
