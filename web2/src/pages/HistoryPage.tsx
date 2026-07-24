import { useCallback, useEffect, useMemo, useState } from 'react'
import { Navigate, useNavigate } from 'react-router-dom'
import {
  BarChart3,
  CalendarRange,
  CheckCircle2,
  CircleDollarSign,
  History,
  LogOut,
  PackagePlus,
  Plus,
  UserPlus,
  UserRound,
  UserX,
  Users,
} from 'lucide-react'
import { activityApi } from '@/api'
import { AuthError } from '@/api/client'
import { useAuth } from '@/context/AuthContext'
import { useToast } from '@/context/ToastContext'
import { AppShell, NavItem } from '@/components/AppShell'
import { Button } from '@/components/ui/button'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import { cn, formatNumber } from '@/lib/utils'
import type { Activity, ActivityKind } from '@/types'

function kindMeta(kind: ActivityKind) {
  switch (kind) {
    case 'lesson':
      return {
        icon: CheckCircle2,
        className: 'bg-primary text-primary-foreground',
      }
    case 'missed':
      return {
        icon: UserX,
        className: 'bg-foreground/85 text-background',
      }
    case 'payment':
      return {
        icon: CircleDollarSign,
        className: 'bg-[var(--warning)] text-white',
      }
    case 'renew':
      return {
        icon: PackagePlus,
        className: 'bg-[#2f6f5e] text-white',
      }
    case 'student':
      return {
        icon: UserPlus,
        className: 'bg-[#4a6fa5] text-white',
      }
  }
}

function formatWhen(iso: string, shortTime: boolean) {
  const d = new Date(iso)
  if (Number.isNaN(d.getTime())) return ''
  const time = d.toLocaleTimeString('ru-RU', {
    hour: '2-digit',
    minute: '2-digit',
  })
  if (shortTime) return time
  return d.toLocaleString('ru-RU', {
    day: 'numeric',
    month: 'short',
    hour: '2-digit',
    minute: '2-digit',
  })
}

function dayKey(iso: string) {
  const d = new Date(iso)
  return `${d.getFullYear()}-${d.getMonth()}-${d.getDate()}`
}

function dayLabel(iso: string) {
  const d = new Date(iso)
  const now = new Date()
  const sameDay =
    d.getFullYear() === now.getFullYear() &&
    d.getMonth() === now.getMonth() &&
    d.getDate() === now.getDate()
  if (sameDay) return 'Сегодня'
  const yesterday = new Date(now)
  yesterday.setDate(now.getDate() - 1)
  if (
    d.getFullYear() === yesterday.getFullYear() &&
    d.getMonth() === yesterday.getMonth() &&
    d.getDate() === yesterday.getDate()
  ) {
    return 'Вчера'
  }
  return d.toLocaleDateString('ru-RU', {
    day: 'numeric',
    month: 'long',
    weekday: 'short',
  })
}

export function HistoryPage() {
  const { isAuthenticated, teacherName, logout } = useAuth()
  const { show } = useToast()
  const navigate = useNavigate()

  const [items, setItems] = useState<Activity[]>([])
  const [loading, setLoading] = useState(true)

  const handleUnauthorized = useCallback(() => {
    logout()
    navigate('/login', { replace: true })
  }, [logout, navigate])

  const load = useCallback(async () => {
    try {
      const data = await activityApi.list('all')
      if (!data.status) {
        show(data.message || 'Не удалось загрузить историю', 'danger')
        return
      }
      setItems(data.data || [])
    } catch (e) {
      if (e instanceof AuthError) handleUnauthorized()
      else show('Нет связи с сервером', 'danger')
    } finally {
      setLoading(false)
    }
  }, [handleUnauthorized, show])

  useEffect(() => {
    if (!isAuthenticated) return
    setLoading(true)
    void load()
  }, [isAuthenticated, load])

  const groups = useMemo(() => {
    const map = new Map<string, Activity[]>()
    for (const item of items) {
      const key = dayKey(item.created_at)
      const list = map.get(key) || []
      list.push(item)
      map.set(key, list)
    }
    return [...map.entries()].map(([key, list]) => ({
      key,
      label: dayLabel(list[0]?.created_at || ''),
      items: list,
    }))
  }, [items])

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />
  }

  const brand = (
    <div className="flex items-center gap-2">
      <div className="flex size-8 items-center justify-center rounded-lg bg-primary text-primary-foreground lg:size-9 lg:rounded-xl">
        <svg viewBox="0 0 24 24" className="h-3.5 w-3.5 fill-current lg:h-4 lg:w-4" aria-hidden>
          <path d="M12 3v10.55A4 4 0 1 0 14 17V7h4V3h-6z" />
        </svg>
      </div>
      <div className="min-w-0">
        <p className="font-display text-lg leading-none tracking-tight italic lg:text-xl">
          CON ANIMA
        </p>
        <p className="mt-1 hidden text-[11px] text-muted-foreground lg:block">
          Кабинет
        </p>
      </div>
    </div>
  )

  const sideNav = (
    <>
      <NavItem
        icon={<Users size={18} />}
        label="Ученики"
        onClick={() => navigate('/')}
      />
      <NavItem
        active
        icon={<History size={18} />}
        label="История"
        onClick={() => navigate('/history')}
      />
      <NavItem
        icon={<CalendarRange size={18} />}
        label="Расписание"
        onClick={() => navigate('/?open=schedule')}
      />
      <NavItem
        icon={<BarChart3 size={18} />}
        label="Итоги"
        onClick={() => navigate('/?open=summary')}
      />
    </>
  )

  const profileMenu = (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button type="button" variant="ghost" className="h-9 gap-2 rounded-xl px-2">
          <span className="flex size-8 items-center justify-center rounded-full bg-accent text-accent-foreground">
            <UserRound size={15} />
          </span>
          <span className="hidden max-w-28 truncate text-sm font-medium md:inline">
            {teacherName || 'Профиль'}
          </span>
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end" className="w-52">
        <DropdownMenuLabel className="font-normal">
          <p className="text-sm font-semibold">{teacherName || 'Преподаватель'}</p>
          <p className="text-xs text-muted-foreground">CON ANIMA</p>
        </DropdownMenuLabel>
        <DropdownMenuSeparator />
        <DropdownMenuItem
          className="text-destructive focus:text-destructive"
          onClick={() => {
            logout()
            navigate('/login')
          }}
        >
          <LogOut size={16} />
          Выйти
        </DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  )

  return (
    <AppShell
      brand={brand}
      nav={sideNav}
      topRight={profileMenu}
      mobileCols={5}
      sidebarFooter={
        <p className="px-1 text-[11px] leading-relaxed text-muted-foreground">
          Журнал уроков и оплат
        </p>
      }
      mobileNav={
        <>
          <NavItem
            variant="bottom"
            icon={<Users size={18} />}
            label="Ученики"
            onClick={() => navigate('/')}
          />
          <NavItem
            variant="bottom"
            active
            icon={<History size={18} />}
            label="История"
            onClick={() => navigate('/history')}
          />
          <NavItem
            variant="bottom"
            icon={<CalendarRange size={18} />}
            label="Неделя"
            onClick={() => navigate('/?open=schedule')}
          />
          <NavItem
            variant="bottom"
            icon={<BarChart3 size={18} />}
            label="Итоги"
            onClick={() => navigate('/?open=summary')}
          />
          <NavItem
            variant="bottom"
            icon={<Plus size={20} strokeWidth={2.5} />}
            label="Новый"
            emphasis
            onClick={() => navigate('/?open=new')}
          />
        </>
      }
    >
      <div className="mx-auto max-w-2xl">
        <div className="mb-5">
          <h1 className="font-sans text-xl font-semibold tracking-tight sm:text-3xl">
            История
          </h1>
        </div>

        {loading ? (
          <div className="space-y-2.5">
            {[1, 2, 3, 4].map((i) => (
              <div
                key={i}
                className="h-[4.25rem] animate-pulse rounded-2xl bg-card"
              />
            ))}
          </div>
        ) : groups.length === 0 ? (
          <div className="rounded-2xl border border-dashed border-border bg-card px-5 py-14 text-center">
            <p className="text-base font-semibold">Пока пусто</p>
            <p className="mx-auto mt-2 max-w-sm text-sm text-muted-foreground">
              Здесь появятся проведённые уроки, пропуски и оплаты.
            </p>
          </div>
        ) : (
          <div className="space-y-5">
            {groups.map((group) => (
              <section key={group.key}>
                <h2 className="mb-2.5 px-0.5 text-xs font-semibold tracking-wide text-muted-foreground uppercase">
                  {group.label}
                </h2>
                <ul className="overflow-hidden rounded-2xl border border-border bg-card">
                  {group.items.map((item, idx) => {
                    const meta = kindMeta(item.kind)
                    const Icon = meta.icon
                    const shortTime =
                      group.label === 'Сегодня' || group.label === 'Вчера'
                    return (
                      <li
                        key={item.id}
                        className={cn(
                          'flex items-center gap-3 px-4 py-3.5',
                          idx > 0 && 'border-t border-border',
                        )}
                      >
                        <span
                          className={cn(
                            'flex size-10 shrink-0 items-center justify-center rounded-xl',
                            meta.className,
                          )}
                          aria-hidden
                        >
                          <Icon size={18} strokeWidth={2.25} />
                        </span>
                        <div className="min-w-0 flex-1">
                          <div className="flex items-baseline justify-between gap-3">
                            <p className="truncate text-[15px] font-semibold leading-snug text-foreground">
                              {item.title}
                            </p>
                            <time className="shrink-0 text-xs tabular-nums text-muted-foreground">
                              {formatWhen(item.created_at, shortTime)}
                            </time>
                          </div>
                          <p className="mt-1 text-sm leading-snug text-muted-foreground">
                            {item.detail}
                            {item.amount != null && item.amount > 0 && (
                              <>
                                {' · '}
                                <span className="font-medium tabular-nums text-foreground">
                                  {formatNumber(item.amount)} ₸
                                </span>
                              </>
                            )}
                          </p>
                        </div>
                      </li>
                    )
                  })}
                </ul>
              </section>
            ))}
          </div>
        )}
      </div>
    </AppShell>
  )
}
