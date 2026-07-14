import {
  createContext,
  useCallback,
  useContext,
  useMemo,
  useState,
  type ReactNode,
} from 'react'
import {
  clearAuth,
  getTeacherName,
  getToken,
  setAuth as persistAuth,
} from '../api/client'

interface AuthContextValue {
  token: string | null
  teacherName: string | null
  isAuthenticated: boolean
  login: (token: string, teacherName?: string) => void
  logout: () => void
}

const AuthContext = createContext<AuthContextValue | null>(null)

export function AuthProvider({ children }: { children: ReactNode }) {
  const [token, setToken] = useState<string | null>(() => getToken())
  const [teacherName, setTeacherName] = useState<string | null>(() =>
    getTeacherName(),
  )

  const login = useCallback((newToken: string, name?: string) => {
    persistAuth(newToken, name)
    setToken(newToken)
    setTeacherName(name ?? null)
  }, [])

  const logout = useCallback(() => {
    clearAuth()
    setToken(null)
    setTeacherName(null)
  }, [])

  const value = useMemo(
    () => ({
      token,
      teacherName,
      isAuthenticated: Boolean(token),
      login,
      logout,
    }),
    [token, teacherName, login, logout],
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth must be used within AuthProvider')
  return ctx
}
