import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { cn } from '@/lib/utils'

interface FieldProps {
  label: string
  value: string
  onChange: (v: string) => void
  type?: string
  required?: boolean
  id?: string
  className?: string
}

export function Field({
  label,
  value,
  onChange,
  type = 'text',
  required,
  id,
  className,
}: FieldProps) {
  const fieldId = id ?? label.replace(/\s+/g, '-').toLowerCase()

  return (
    <div className={cn('space-y-1.5', className)}>
      <Label htmlFor={fieldId} className="text-sm font-medium text-muted-foreground font-sans">
        {label}
      </Label>
      <Input
        id={fieldId}
        type={type}
        required={required}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        className="h-11 rounded-xl bg-card font-sans touch-target"
      />
    </div>
  )
}
