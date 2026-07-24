# CON ANIMA iOS

Нативный SwiftUI-клиент кабинета преподавателя. Порт `web2`, тот же API.

## Требования

- Xcode 16+
- iOS 17+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`
- Prod API: `http://46.101.212.67:3000/api/v1` (см. `APIBaseURL` в Info.plist)

## Запуск

```bash
cd ios
xcodegen generate
open ConAnima.xcodeproj
```

По умолчанию приложение ходит на прод. Для локального бэка смени `APIBaseURL` на `http://localhost:3000/api/v1`.

## Что есть

- Login / logout
- Ученики: поиск, фильтры, chips, CRUD
- Провести / пропуск / продлить
- Расписание ученика и недели (сегодня + week)
- Итоги + график года
- История активности
- Haptics, spring-анимации карточек, native sheets

## Промпт

См. [PROMPT.md](./PROMPT.md) — Mobile App Builder + Apple-Level UI + контракт web2.
