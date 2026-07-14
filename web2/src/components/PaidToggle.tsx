import { cn } from '@/lib/utils'
import { copy } from '@/lib/copy'

interface PaidToggleProps {
  value: boolean
  onChange: (value: boolean) => void
  className?: string
}

/** Ряд статуса оплаты — на всю ширину формы */
export function PaidToggle({ value, onChange, className }: PaidToggleProps) {
  return (
    <div
      className={cn(
        'flex items-center justify-between gap-3 rounded-xl border border-border bg-muted/50 px-3.5 py-3',
        className,
      )}
    >
      <div className="min-w-0">
        <p className="text-sm font-medium text-foreground">Оплата</p>
        <p className="mt-0.5 text-xs text-muted-foreground">
          {value ? copy.paidToggleHintOn : copy.paidToggleHintOff}
        </p>
      </div>

      <div
        role="group"
        aria-label="Статус оплаты"
        className="inline-flex shrink-0 rounded-lg bg-card p-0.5 ring-1 ring-border"
      >
        <button
          type="button"
          onClick={() => onChange(false)}
          aria-pressed={!value}
          className={cn(
            'rounded-md px-3 py-1.5 text-xs font-semibold transition',
            !value
              ? 'bg-destructive/10 text-destructive shadow-sm'
              : 'text-muted-foreground hover:text-foreground',
          )}
        >
          {copy.paidToggleOff}
        </button>
        <button
          type="button"
          onClick={() => onChange(true)}
          aria-pressed={value}
          className={cn(
            'rounded-md px-3 py-1.5 text-xs font-semibold transition',
            value
              ? 'bg-primary text-primary-foreground shadow-sm'
              : 'text-muted-foreground hover:text-foreground',
          )}
        >
          {copy.paidToggleOn}
        </button>
      </div>
    </div>
  )
}
