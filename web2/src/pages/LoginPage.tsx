import { useState, type FormEvent } from 'react'
import { Navigate, useNavigate } from 'react-router-dom'
import { login as loginRequest } from '@/api/client'
import { useAuth } from '@/context/AuthContext'
import { useToast } from '@/context/ToastContext'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'

export function LoginPage() {
  const { login, isAuthenticated } = useAuth()
  const { show } = useToast()
  const navigate = useNavigate()
  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)

  if (isAuthenticated) {
    return <Navigate to="/" replace />
  }

  async function handleSubmit(e: FormEvent) {
    e.preventDefault()
    if (!username.trim() || !password) {
      show('Заполните логин и пароль', 'danger')
      return
    }

    setLoading(true)
    try {
      const data = await loginRequest(username.trim(), password)
      if (data.status && data.token) {
        login(data.token, data.teacher?.first_name)
        navigate('/')
      } else {
        show(data.message || 'Неверный логин или пароль', 'danger')
      }
    } catch {
      show('Нет связи с сервером', 'danger')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="relative flex min-h-screen">
      {/* Soft brand panel — desktop */}
      <div className="relative hidden w-[46%] overflow-hidden bg-[#eef2ff] lg:flex lg:flex-col lg:justify-between lg:p-12 xl:p-16">
        <div
          className="pointer-events-none absolute -right-20 top-20 size-72 rounded-full bg-primary/15 blur-3xl"
          aria-hidden
        />
        <div
          className="pointer-events-none absolute bottom-10 left-10 size-56 rounded-full bg-[#c8d4ff]/60 blur-3xl"
          aria-hidden
        />
        <p className="font-display text-4xl tracking-tight text-foreground italic">
          CON ANIMA
        </p>
        <div className="relative max-w-sm space-y-3">
          <h1 className="text-3xl font-semibold leading-tight tracking-tight text-foreground xl:text-4xl">
            Кабинет для спокойной работы с учениками
          </h1>
          <p className="text-base leading-relaxed text-muted-foreground">
            Уроки, оплаты и расписание — в одном лёгком пространстве.
          </p>
        </div>
        <p className="text-sm text-muted-foreground">Музыкальная школа</p>
      </div>

      {/* Form */}
      <div className="flex flex-1 items-center justify-center px-5 py-12">
        <div className="w-full max-w-[380px]">
          <div className="mb-8 lg:hidden">
            <p className="font-display text-3xl tracking-tight text-foreground italic">
              CON ANIMA
            </p>
            <p className="mt-1 text-sm text-muted-foreground">
              Вход для преподавателя
            </p>
          </div>

          <div className="hidden lg:block">
            <h2 className="text-2xl font-semibold tracking-tight">
              С возвращением
            </h2>
            <p className="mt-1 text-sm text-muted-foreground">
              Войдите в кабинет преподавателя
            </p>
          </div>

          <form onSubmit={handleSubmit} className="mt-8 space-y-5">
            <div className="space-y-1.5">
              <Label htmlFor="login-username">Логин</Label>
              <Input
                id="login-username"
                type="text"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                autoComplete="username"
                placeholder="Ваш логин"
                className="h-11 rounded-xl bg-card"
                required
              />
            </div>

            <div className="space-y-1.5">
              <Label htmlFor="login-password">Пароль</Label>
              <Input
                id="login-password"
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                autoComplete="current-password"
                placeholder="Пароль"
                className="h-11 rounded-xl bg-card"
                required
              />
            </div>

            <Button
              type="submit"
              disabled={loading}
              className="h-11 w-full rounded-xl text-sm font-semibold"
            >
              {loading ? 'Входим…' : 'Войти'}
            </Button>
          </form>
        </div>
      </div>
    </div>
  )
}
