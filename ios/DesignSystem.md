# iOS Design Notes (CON ANIMA)

Patterns we mirror (pet-link / Boxmind) + local rules:

- **List → Detail**: compact row (`StudentRowView`) + `NavigationLink` → detail (`StudentDetailView`)
- **Hidden chevron**: `.navigationLinkIndicatorVisibility(.hidden)`
- **Detail layout**: `ScrollView` on `systemGroupedBackground`, rounded title, fact chips, sticky bottom CTAs
- **Row chrome**: white card on soft indigo canvas (`AppTheme.canvas` / `AppCanvasBackground`), light padding, no metric boxes on list rows
- **Status pills**: shared `StatusCapsule` — fixed 11pt semibold (same for «Не оплачено» / «Закончился»)
- **Spacing**: multiples of 8
- **Journal**: `List` + large title like Students — segment scrolls away, frosted nav bar keeps title

## Buttons (единый код)

Все основные CTA — **capsule**, высота `AppTheme.buttonHeight` (52).

| Компонент | Когда |
|-----------|--------|
| `HoldToAction` | Подтверждение удержанием («Провести урок») |
| `AppPrimaryButton` | Обычный primary CTA («Добавить в расписание») — тот же цвет/обводка, что idle у Hold |
| `AppSecondaryButton` | Вторичное действие («Отметить пропуск») |

Не использовать ad-hoc `borderedProminent` / solid fill для bottom CTAs — только эти компоненты.
Primary fill: `AppTheme.primary.opacity(0.10)` + stroke `0.22`, текст `0.85`.

See `/Users/abramov/Desktop/pet-link/apps/ios/DesignSystem.md` and `BookmarkDetailView.swift`.
