import {
  createContext,
  useCallback,
  useContext,
  useMemo,
  useState,
  type ReactNode,
} from 'react'
import { AlertCircle, CheckCircle2, Info, TriangleAlert, X } from 'lucide-react'
import { cn } from '@/lib/utils'

type ToastType = 'danger' | 'success' | 'warning' | 'info'

interface Toast {
  id: number
  message: string
  type: ToastType
}

interface ToastContextValue {
  show: (message: string, type?: ToastType) => void
}

const ToastContext = createContext<ToastContextValue | null>(null)

const styles: Record<ToastType, string> = {
  danger: 'border-destructive/30 bg-card text-destructive',
  success: 'border-primary/30 bg-card text-foreground',
  warning: 'border-[#f0a05a]/40 bg-card text-[#d48a2e]',
  info: 'border-border bg-card text-foreground',
}

const icons: Record<ToastType, typeof AlertCircle> = {
  danger: AlertCircle,
  success: CheckCircle2,
  warning: TriangleAlert,
  info: Info,
}

const iconClass: Record<ToastType, string> = {
  danger: 'text-destructive',
  success: 'text-primary',
  warning: 'text-[#d48a2e]',
  info: 'text-muted-foreground',
}

export function ToastProvider({ children }: { children: ReactNode }) {
  const [toasts, setToasts] = useState<Toast[]>([])

  const show = useCallback((message: string, type: ToastType = 'danger') => {
    const id = Date.now() + Math.random()
    setToasts((prev) => [...prev, { id, message, type }])
    setTimeout(() => {
      setToasts((prev) => prev.filter((t) => t.id !== id))
    }, 3500)
  }, [])

  const value = useMemo(() => ({ show }), [show])

  return (
    <ToastContext.Provider value={value}>
      {children}
      <div
        className="pointer-events-none fixed inset-x-4 top-4 z-[100] flex flex-col gap-2 sm:inset-x-auto sm:right-4 sm:left-auto sm:w-full sm:max-w-sm"
        aria-live="polite"
      >
        {toasts.map((toast) => {
          const Icon = icons[toast.type]
          return (
            <div
              key={toast.id}
              role="status"
              className={cn(
                'pointer-events-auto animate-fade-up flex items-start gap-3 rounded-xl border px-4 py-3 shadow-lg',
                styles[toast.type],
              )}
            >
              <Icon
                size={18}
                className={cn('mt-0.5 shrink-0', iconClass[toast.type])}
                aria-hidden
              />
              <p className="flex-1 text-sm font-medium leading-snug">
                {toast.message}
              </p>
              <button
                type="button"
                className="shrink-0 rounded-md p-1 opacity-70 transition hover:opacity-100 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
                aria-label="Закрыть"
                onClick={() =>
                  setToasts((prev) => prev.filter((t) => t.id !== toast.id))
                }
              >
                <X size={16} />
              </button>
            </div>
          )
        })}
      </div>
    </ToastContext.Provider>
  )
}

export function useToast() {
  const ctx = useContext(ToastContext)
  if (!ctx) throw new Error('useToast must be used within ToastProvider')
  return ctx
}
