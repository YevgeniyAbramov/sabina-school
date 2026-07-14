# CON ANIMA — Web2

Отдельный React + Tailwind фронтенд для школы CON ANIMA.
Логика API та же (`/api/v1`), бэкенд Go не меняется.

## Стек

- Vite + React 19 + TypeScript
- Tailwind CSS v4
- React Router
- Recharts
- Lucide icons

## Запуск

1. Поднимите бэкенд на порту `3000` (из корня репозитория).
2. В этой папке:

```bash
npm install
npm run dev
```

Приложение: http://localhost:5173  
API проксируется на `http://localhost:3000`.

## Сборка

```bash
npm run build
```

Артефакты в `dist/`. Можно раздавать статикой или через nginx рядом с API.
