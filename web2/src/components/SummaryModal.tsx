import { useEffect, useMemo, useState } from 'react'
import {
  Line,
  LineChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
} from 'recharts'
import { Modal } from '@/components/Modal'
import { summaryApi } from '@/api'
import { AuthError } from '@/api/client'
import { cn, formatNumber, MONTH_NAMES, MONTH_SHORT } from '@/lib/utils'
import { copy } from '@/lib/copy'
import type { Student } from '@/types'

interface Props {
  open: boolean
  students: Student[]
  onClose: () => void
  onUnauthorized: () => void
}

export function SummaryModal({
  open,
  students,
  onClose,
  onUnauthorized,
}: Props) {
  const now = new Date()
  const month = now.getMonth() + 1
  const year = now.getFullYear()

  const [amount, setAmount] = useState(0)
  const [monthlyData, setMonthlyData] = useState<number[]>(Array(12).fill(0))
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    if (!open) return
    setLoading(true)

    summaryApi
      .get(year, month)
      .then((data) => {
        if (data.status && data.data) {
          setAmount(Number(data.data.total_amount) || 0)
        } else {
          setAmount(0)
        }
      })
      .catch((e) => {
        if (e instanceof AuthError) onUnauthorized()
        setAmount(0)
      })

    Promise.all(
      Array.from({ length: 12 }, (_, i) =>
        summaryApi
          .get(year, i + 1)
          .then((d) =>
            d.status && d.data ? Number(d.data.total_amount) || 0 : 0,
          )
          .catch(() => 0),
      ),
    )
      .then(setMonthlyData)
      .finally(() => setLoading(false))
  }, [open, year, month, onUnauthorized])

  const stats = useMemo(() => {
    const paid = students.filter((s) => s.is_paid).length
    const unpaid = students.length - paid
    let done = 0
    let left = 0
    let missed = 0

    for (const s of students) {
      const total = Math.max(0, Number(s.total_lessons) || 0)
      const remaining = Math.min(
        total,
        Math.max(0, Number(s.remaining_lessons) || 0),
      )
      let m = Math.max(0, Number(s.missed_classes) || 0)
      if (total > 0 && m > total) m = 0
      done += Math.max(0, total - remaining)
      left += remaining
      missed += m
    }

    const lessonTotal = done + left + missed || 1
    return {
      paid,
      unpaid,
      done,
      left,
      missed,
      lessonTotal,
      lowStock: students.filter((s) => s.remaining_lessons === 1).length,
    }
  }, [students])

  const lineData = MONTH_SHORT.map((name, i) => ({
    name,
    amount: monthlyData[i],
  }))

  return (
    <Modal open={open} onClose={onClose} title="Итоги" size="xl">
      <div className="space-y-5">
        {/* Главный показатель месяца */}
        <div className="rounded-2xl border border-border bg-card px-5 py-5 sm:px-6">
          <p className="text-sm text-muted-foreground">
            Выручка · {MONTH_NAMES[month - 1]} {year}
          </p>
          <p className="mt-2 text-3xl font-semibold tracking-tight tabular-nums text-foreground sm:text-[2.5rem]">
            {loading ? '…' : `${formatNumber(amount)} ₸`}
          </p>
        </div>

        {/* KPI плитки вместо pie */}
        <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
          <Kpi label="Учеников" value={String(students.length)} />
          <Kpi
            label={copy.paid}
            value={String(stats.paid)}
            tone="ok"
          />
          <Kpi
            label={copy.unpaid}
            value={String(stats.unpaid)}
            tone={stats.unpaid > 0 ? 'bad' : 'default'}
          />
          <Kpi
            label={copy.endingSoon}
            value={String(stats.lowStock)}
            hint={
              stats.lowStock > 0
                ? copy.endingSoonHint
                : 'у всех есть запас'
            }
            tone={stats.lowStock > 0 ? 'warn' : 'default'}
          />
        </div>

        {/* Прогресс по урокам вместо bar chart */}
        <section className="rounded-2xl border border-border bg-card px-5 py-5">
          <h3 className="text-sm font-semibold text-foreground">Занятия</h3>
          <p className="mt-1 text-xs text-muted-foreground">
            По всем ученикам разом
          </p>
          <div className="mt-4 space-y-3.5">
            <ProgressRow
              label="Проведено"
              value={stats.done}
              total={stats.lessonTotal}
              color="bg-primary"
            />
            <ProgressRow
              label="Впереди"
              value={stats.left}
              total={stats.lessonTotal}
              color="bg-[#4db6a1]"
            />
            <ProgressRow
              label="Пропуски"
              value={stats.missed}
              total={stats.lessonTotal}
              color="bg-[#f0a05a]"
            />
          </div>
        </section>

        {/* Лёгкий тренд — единственный график */}
        <section className="rounded-2xl border border-border bg-card px-5 py-5">
          <div className="mb-3 flex items-baseline justify-between gap-2">
            <h3 className="text-sm font-semibold text-foreground">
              По месяцам
            </h3>
            <span className="text-xs text-muted-foreground">{year}</span>
          </div>
          <div className="h-[140px] w-full">
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={lineData} margin={{ top: 8, right: 4, left: 0, bottom: 0 }}>
                <XAxis
                  dataKey="name"
                  tick={{ fontSize: 11, fill: '#6d7489' }}
                  axisLine={false}
                  tickLine={false}
                />
                <Tooltip
                  contentStyle={{
                    borderRadius: 12,
                    border: '1px solid #e6e8ef',
                    fontSize: 12,
                  }}
                  formatter={(v) => [
                    `${Number(v).toLocaleString('ru-RU')} ₸`,
                    'Выручка',
                  ]}
                />
                <Line
                  type="monotone"
                  dataKey="amount"
                  stroke="#5b7cfa"
                  strokeWidth={2.5}
                  dot={false}
                  activeDot={{ r: 4 }}
                />
              </LineChart>
            </ResponsiveContainer>
          </div>
        </section>
      </div>
    </Modal>
  )
}

function Kpi({
  label,
  value,
  hint,
  tone = 'default',
}: {
  label: string
  value: string
  hint?: string
  tone?: 'default' | 'ok' | 'bad' | 'warn'
}) {
  return (
    <div className="rounded-2xl border border-border bg-card px-3.5 py-3.5 sm:px-4">
      <p className="text-[11px] font-medium text-muted-foreground">{label}</p>
      <p
        className={cn(
          'mt-1.5 text-2xl font-semibold tabular-nums tracking-tight',
          tone === 'ok' && 'text-[var(--success)]',
          tone === 'bad' && 'text-destructive',
          tone === 'warn' && 'text-[var(--warning)]',
          tone === 'default' && 'text-foreground',
        )}
      >
        {value}
      </p>
      {hint && (
        <p className="mt-0.5 text-[10px] text-muted-foreground">{hint}</p>
      )}
    </div>
  )
}

function ProgressRow({
  label,
  value,
  total,
  color,
}: {
  label: string
  value: number
  total: number
  color: string
}) {
  const pct = Math.min(100, Math.round((value / total) * 100))
  return (
    <div>
      <div className="mb-1.5 flex items-center justify-between text-sm">
        <span className="text-muted-foreground">{label}</span>
        <span className="font-semibold tabular-nums text-foreground">
          {value}
        </span>
      </div>
      <div className="h-2 overflow-hidden rounded-full bg-muted">
        <div
          className={cn('h-full rounded-full transition-[width]', color)}
          style={{ width: `${pct}%` }}
        />
      </div>
    </div>
  )
}
