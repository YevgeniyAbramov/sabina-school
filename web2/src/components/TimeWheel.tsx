import { useEffect, useRef } from 'react'
import { cn } from '@/lib/utils'

interface TimeWheelProps {
  hour: string
  minute: string
  onHourChange: (v: string) => void
  onMinuteChange: (v: string) => void
}

const HOURS = Array.from({ length: 15 }, (_, i) => String(i + 7))
const MINUTES = Array.from({ length: 12 }, (_, i) =>
  String(i * 5).padStart(2, '0'),
)

const ITEM = 40
const PAD = 48

function Wheel({
  items,
  value,
  onChange,
}: {
  items: string[]
  value: string
  onChange: (v: string) => void
}) {
  const ref = useRef<HTMLDivElement>(null)
  const ticking = useRef(false)

  useEffect(() => {
    const el = ref.current
    if (!el) return
    const idx = items.findIndex((it) => it === value || Number(it) === Number(value))
    if (idx >= 0) {
      el.scrollTop = PAD + idx * ITEM - el.clientHeight / 2 + ITEM / 2
    }
  }, [items, value])

  const update = () => {
    const el = ref.current
    if (!el) return
    const center = el.scrollTop + el.clientHeight / 2 - ITEM / 2
    let selected = items[0]
    for (let i = 0; i < items.length; i++) {
      const top = PAD + i * ITEM
      if (top <= center && center < top + ITEM) {
        selected = items[i]
        break
      }
    }
    if (selected !== value) onChange(selected)
  }

  return (
    <div
      ref={ref}
      onScroll={() => {
        if (ticking.current) return
        ticking.current = true
        requestAnimationFrame(() => {
          update()
          ticking.current = false
        })
      }}
      className="h-[128px] w-16 overflow-y-auto scroll-smooth rounded-xl bg-muted snap-y"
      style={{ scrollbarWidth: 'none' }}
    >
      <div style={{ height: PAD }} />
      {items.map((it) => {
        const selected = it === value || Number(it) === Number(value)
        return (
          <div
            key={it}
            className={cn(
              'flex h-10 snap-center items-center justify-center text-sm transition-colors',
              selected
                ? 'font-semibold text-primary'
                : 'text-muted-foreground/50',
            )}
          >
            {it.padStart(2, '0')}
          </div>
        )
      })}
      <div style={{ height: PAD }} />
    </div>
  )
}

export function TimeWheel({
  hour,
  minute,
  onHourChange,
  onMinuteChange,
}: TimeWheelProps) {
  return (
    <div className="flex items-center justify-center gap-2">
      <Wheel items={HOURS} value={hour} onChange={onHourChange} />
      <span className="font-display text-xl font-semibold text-foreground">:</span>
      <Wheel items={MINUTES} value={minute} onChange={onMinuteChange} />
    </div>
  )
}
