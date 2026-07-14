import type { ReactNode } from 'react'
import { useIsDesktop } from '@/hooks/use-media-query'
import { cn } from '@/lib/utils'
import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import {
  Sheet,
  SheetContent,
  SheetFooter,
  SheetHeader,
  SheetTitle,
} from '@/components/ui/sheet'

interface ModalProps {
  open: boolean
  onClose: () => void
  title: string
  children: ReactNode
  footer?: ReactNode
  size?: 'md' | 'lg' | 'xl'
  danger?: boolean
  description?: string
}

const sizeClass = {
  md: 'sm:max-w-md',
  lg: 'sm:max-w-lg',
  xl: 'sm:max-w-3xl',
}

export function Modal({
  open,
  onClose,
  title,
  children,
  footer,
  size = 'md',
  danger = false,
}: ModalProps) {
  const isDesktop = useIsDesktop()

  if (isDesktop) {
    return (
      <Dialog open={open} onOpenChange={(v) => !v && onClose()}>
        <DialogContent
          className={cn(
            'flex max-h-[90vh] flex-col gap-0 overflow-hidden p-0',
            sizeClass[size],
          )}
          showCloseButton
        >
          <DialogHeader
            className={cn(
              'shrink-0 border-b px-5 py-4 pr-12 text-left',
              danger && 'border-destructive/20 bg-destructive text-white',
            )}
          >
            <DialogTitle
              className={cn(
                'text-base font-semibold tracking-tight sm:text-lg',
                danger ? 'text-white' : 'text-foreground',
              )}
            >
              {title}
            </DialogTitle>
          </DialogHeader>
          <div className="min-h-0 flex-1 overflow-y-auto px-5 py-5">
            {children}
          </div>
          {footer && (
            <DialogFooter className="mx-0 mb-0 shrink-0 gap-2 rounded-none border-t bg-muted/30 px-5 py-3.5 sm:justify-end">
              {footer}
            </DialogFooter>
          )}
        </DialogContent>
      </Dialog>
    )
  }

  return (
    <Sheet open={open} onOpenChange={(v) => !v && onClose()}>
      <SheetContent
        side="bottom"
        className="max-h-[92vh] gap-0 rounded-t-2xl p-0"
        showCloseButton
      >
        <SheetHeader
          className={cn(
            'shrink-0 border-b px-5 py-4 pr-12 text-left',
            danger && 'border-destructive/20 bg-destructive text-white',
          )}
        >
          <SheetTitle
            className={cn(
              'text-base font-semibold tracking-tight',
              danger ? 'text-white' : 'text-foreground',
            )}
          >
            {title}
          </SheetTitle>
        </SheetHeader>
        <div className="min-h-0 flex-1 overflow-y-auto px-5 py-5">{children}</div>
        {footer && (
          <SheetFooter className="safe-bottom shrink-0 gap-2 border-t bg-muted/30 px-5 py-3.5 sm:flex-row sm:justify-end">
            {footer}
          </SheetFooter>
        )}
      </SheetContent>
    </Sheet>
  )
}
