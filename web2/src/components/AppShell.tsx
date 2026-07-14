import type { ReactNode } from 'react'
import { cn } from '@/lib/utils'

interface AppShellProps {
  brand: ReactNode
  nav: ReactNode
  mobileNav?: ReactNode
  topRight?: ReactNode
  sidebarFooter?: ReactNode
  children: ReactNode
  className?: string
}

export function AppShell({
  brand,
  nav,
  mobileNav,
  topRight,
  sidebarFooter,
  children,
  className,
}: AppShellProps) {
  return (
    <div className={cn('min-h-screen bg-background', className)}>
      <aside className="fixed inset-y-0 left-0 z-40 hidden w-[232px] flex-col border-r border-border bg-sidebar lg:flex">
        <div className="px-4 pb-2 pt-5">{brand}</div>
        <nav className="mt-2 flex flex-1 flex-col gap-0.5 px-2.5" aria-label="Разделы">
          {nav}
        </nav>
        {sidebarFooter && (
          <div className="border-t border-border px-3 py-3">{sidebarFooter}</div>
        )}
      </aside>

      <div className="lg:pl-[232px]">
        <header className="sticky top-0 z-30 flex h-12 items-center justify-between gap-3 border-b border-border bg-card/95 px-4 backdrop-blur-md lg:hidden">
          <div className="min-w-0">{brand}</div>
          <div className="flex shrink-0 items-center">{topRight}</div>
        </header>

        <div className="sticky top-0 z-30 hidden h-14 items-center justify-end gap-2 border-b border-border bg-card/80 px-6 backdrop-blur-md lg:flex">
          {topRight}
        </div>

        <main className="px-3.5 py-4 pb-24 sm:px-6 sm:py-6 lg:px-8 lg:pb-10">
          {children}
        </main>
      </div>

      {mobileNav && (
        <nav
          className="fixed inset-x-0 bottom-0 z-40 border-t border-border bg-card/95 backdrop-blur-md safe-bottom lg:hidden"
          aria-label="Мобильная навигация"
        >
          <div className="mx-auto grid max-w-lg grid-cols-4 items-end px-2 pt-1">
            {mobileNav}
          </div>
        </nav>
      )}
    </div>
  )
}

export function NavItem({
  active,
  icon,
  label,
  onClick,
  variant = 'side',
  emphasis,
}: {
  active?: boolean
  icon: ReactNode
  label: string
  onClick: () => void
  variant?: 'side' | 'bottom'
  /** Выделенная кнопка «Новый» в таббаре */
  emphasis?: boolean
}) {
  if (variant === 'bottom') {
    if (emphasis) {
      return (
        <button
          type="button"
          onClick={onClick}
          className="flex flex-col items-center justify-end gap-1 pb-1"
        >
          <span className="flex size-11 items-center justify-center rounded-2xl bg-primary text-primary-foreground shadow-md shadow-primary/25">
            {icon}
          </span>
          <span className="text-[10px] font-semibold text-primary">{label}</span>
        </button>
      )
    }

    return (
      <button
        type="button"
        onClick={onClick}
        className={cn(
          'flex min-h-14 flex-col items-center justify-center gap-1 text-[10px] font-medium transition',
          active ? 'text-primary' : 'text-muted-foreground',
        )}
      >
        <span
          className={cn(
            'flex size-9 items-center justify-center rounded-xl',
            active && 'bg-accent text-accent-foreground',
          )}
        >
          {icon}
        </span>
        {label}
      </button>
    )
  }

  return (
    <button
      type="button"
      onClick={onClick}
      className={cn(
        'flex w-full items-center gap-2.5 rounded-xl px-3 py-2.5 text-sm font-medium transition',
        active
          ? 'bg-accent text-accent-foreground'
          : 'text-muted-foreground hover:bg-muted hover:text-foreground',
      )}
    >
      <span className="opacity-80">{icon}</span>
      {label}
    </button>
  )
}
