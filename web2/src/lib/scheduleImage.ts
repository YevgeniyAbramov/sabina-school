import { DAY_NAMES } from './utils'
import type { ScheduleSlot, Student } from '@/types'

// Soft palette from the project's design system (web2/src/index.css)
const C = {
  bg: '#ffffff',
  foreground: '#1c1f2a',
  muted: '#6d7489',
  border: '#e6e8ef',
  primary: '#5b7cfa',
  primarySoft: '#eef2ff',
  success: '#2f9e8a',
  warning: '#d48a2e',
  danger: '#e55a5a',
}

const DAY_ORDER = [1, 2, 3, 4, 5, 6, 0]

// Returns the Date for a given day_of_week (0 = Sunday … 6 = Saturday)
// within the current calendar week (Monday-based).
function dateForDayOfWeek(day: number): Date {
  const now = new Date()
  const monday = new Date(now)
  const diffToMonday = (now.getDay() + 6) % 7
  monday.setDate(now.getDate() - diffToMonday)
  monday.setHours(0, 0, 0, 0)
  const offset = day === 0 ? 6 : day - 1
  const d = new Date(monday)
  d.setDate(monday.getDate() + offset)
  return d
}

function formatDate(d: Date): string {
  return d.toLocaleDateString('ru-RU', { day: 'numeric', month: 'long' })
}

function weekRangeLabel(): string {
  return `${formatDate(dateForDayOfWeek(1))} – ${formatDate(dateForDayOfWeek(0))}`
}

function formatTimeSlot(slot?: string): string {
  return (slot || '').split(':').slice(0, 2).join(':')
}

function roundRect(
  ctx: CanvasRenderingContext2D,
  x: number,
  y: number,
  w: number,
  h: number,
  r: number,
) {
  ctx.beginPath()
  ctx.moveTo(x + r, y)
  ctx.arcTo(x + w, y, x + w, y + h, r)
  ctx.arcTo(x + w, y + h, x, y + h, r)
  ctx.arcTo(x, y + h, x, y, r)
  ctx.arcTo(x, y, x + w, y, r)
  ctx.closePath()
}

interface DayGroup {
  day: number
  slots: ScheduleSlot[]
}

export function exportWeekScheduleImage(days: DayGroup[], students: Student[]) {
  const ordered = DAY_ORDER.map(
    (d) => days.find((x) => x.day === d) ?? { day: d, slots: [] },
  )
  const hasAny = ordered.some((d) => d.slots.length > 0)
  if (!hasAny) return

  const studentName = (id: number) => {
    const s = students.find((st) => st.id === id)
    return s ? `${s.first_name} ${s.last_name || ''}`.trim() : `#${id}`
  }

  const W = 920
  const PAD = 52
  const dpr = Math.min(window.devicePixelRatio || 1, 2)

  const HEADER_H = 168
  const DAY_HEADER_H = 46
  const SLOT_H = 44
  const DAY_GAP = 30
  const FOOTER_H = 64

  let contentH = 0
  for (const { slots } of ordered) {
    if (slots.length === 0) continue
    contentH += DAY_HEADER_H
    contentH += slots.length * SLOT_H
    contentH += DAY_GAP
  }
  const H = HEADER_H + contentH + FOOTER_H

  const canvas = document.createElement('canvas')
  canvas.width = W * dpr
  canvas.height = H * dpr
  const ctx = canvas.getContext('2d')
  if (!ctx) return
  ctx.scale(dpr, dpr)

  // Background
  ctx.fillStyle = C.bg
  ctx.fillRect(0, 0, W, H)

  // Brand
  ctx.textBaseline = 'alphabetic'
  ctx.textAlign = 'left'
  ctx.fillStyle = C.primary
  ctx.font = '700 14px Manrope, system-ui, sans-serif'
  ctx.fillText('CON ANIMA', PAD, PAD)

  // Title
  ctx.fillStyle = C.foreground
  ctx.font = '700 32px Manrope, system-ui, sans-serif'
  ctx.fillText('Расписание на неделю', PAD, PAD + 46)

  // Week range
  ctx.fillStyle = C.muted
  ctx.font = '500 16px Manrope, system-ui, sans-serif'
  ctx.fillText(weekRangeLabel(), PAD, PAD + 76)

  // Divider
  ctx.strokeStyle = C.border
  ctx.lineWidth = 1
  ctx.beginPath()
  ctx.moveTo(PAD, PAD + 96)
  ctx.lineTo(W - PAD, PAD + 96)
  ctx.stroke()

  let y = HEADER_H

  for (const { day, slots } of ordered) {
    if (slots.length === 0) continue
    const sorted = [...slots].sort((a, b) =>
      (a.time_slot || '').localeCompare(b.time_slot || ''),
    )
    const date = dateForDayOfWeek(day)

    // Day header
    ctx.fillStyle = C.foreground
    ctx.font = '700 19px Manrope, system-ui, sans-serif'
    ctx.fillText(DAY_NAMES[day], PAD, y + 24)

    ctx.fillStyle = C.muted
    ctx.font = '500 14px Manrope, system-ui, sans-serif'
    ctx.textAlign = 'right'
    ctx.fillText(formatDate(date), W - PAD, y + 24)
    ctx.textAlign = 'left'

    y += DAY_HEADER_H

    for (const s of sorted) {
      const time = formatTimeSlot(s.time_slot)
      const label = studentName(s.student_id)

      // Time pill
      const pillW = 70
      const pillH = 28
      const pillY = y + (SLOT_H - pillH) / 2
      ctx.fillStyle = C.primarySoft
      roundRect(ctx, PAD, pillY, pillW, pillH, 9)
      ctx.fill()
      ctx.fillStyle = C.primary
      ctx.font = '700 14px Manrope, system-ui, sans-serif'
      ctx.textAlign = 'center'
      ctx.fillText(time, PAD + pillW / 2, pillY + 19)
      ctx.textAlign = 'left'

      // Student name
      ctx.fillStyle = C.foreground
      ctx.font = '500 16px Manrope, system-ui, sans-serif'
      ctx.fillText(label, PAD + pillW + 18, y + SLOT_H / 2 + 6)

      y += SLOT_H
    }

    y += DAY_GAP
  }

  // Footer
  ctx.fillStyle = C.muted
  ctx.font = '500 13px Manrope, system-ui, sans-serif'
  ctx.fillText(
    'CON ANIMA — школа музыки',
    PAD,
    H - FOOTER_H / 2,
  )

  // Download
  const url = canvas.toDataURL('image/png')
  const link = document.createElement('a')
  link.href = url
  link.download = `con-anima-schedule-${dateForDayOfWeek(1)
    .toISOString()
    .slice(0, 10)}.png`
  document.body.appendChild(link)
  link.click()
  document.body.removeChild(link)
}
