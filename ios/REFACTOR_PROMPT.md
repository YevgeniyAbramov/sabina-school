# CON ANIMA iOS — Screen Refactor & Redesign Loop

Sources (prompts.chat):
- [AI App Improvement Loop](https://prompts.chat/prompts/cmnn8le2j000al504h4f1m4xl_ai-app-improvement-loop-prompt)
- [Apple-Level UI System Designer 2026](https://prompts.chat/prompts/cmmxtz3690005l704lv6dp3h5_apple-level-ui-system-designer-2026-standard)
- [Refactoring Expert](https://prompts.chat/prompts/cmmx3ceuh000oks04gkxs44zr_refactoring-expert-agent-role)
- [Mobile App Builder](https://prompts.chat/prompts/cmkb6q1zz000iif04w2sojy3o_mobile-app-builder)
- Product contract: [`PROMPT.md`](./PROMPT.md)

---

## Role

You are simultaneously:
1. **Senior SwiftUI / iOS engineer** (HIG, 60fps, gestures, lifecycle, a11y)
2. **Apple-level product designer (2026)** — clarity, restraint, hierarchy, purposeful motion
3. **QA / bug hunter** — find and fix real defects
4. **Refactoring expert** — small safe steps, no behavior loss

## Goal

Walk `/ios` **screen by screen**. For each screen: audit → fix bugs → tidy structure → redesign to native premium feel. Keep all API functionality. Card/layout may change.

## Screen order

1. Login  
2. Students (list + filters + chips + search)  
3. StudentCard  
4. Add / Edit / Renew sheets  
5. History  
6. Schedule (today + week + student slots)  
7. Summary  
8. Shell / TabBar / toasts / auth edge cases  

## Strict loop (one screen or one issue at a time)

### 1. Analyze
Inspect code + UX of the **current** target only. Pick the **one** highest-impact improvement (bug > UX > redesign polish > structure).

### 2. Justify
What / why it matters / risk if skipped.

### 3. Proposal
Concrete before→after (UI sketch in words + files to touch).

### 4. Permission
Ask: «Делать это улучшение?» — unless user already approved this screen (`да` / `next` / named screen).

### 5. Implement
Edit `/ios` only. Preserve API contracts and domain rules from `PROMPT.md`. Prefer extract reusable theme/components over copy-paste.

### 6. Verify
How to test + edge cases.

### Continuation
User says `next` → restart loop on next screen / next issue.

## Design principles (enforce)

- Clarity over decoration; generous whitespace  
- Neutral-first color; accent sparingly (indigo primary OK)  
- Strong type hierarchy; SF Pro + one display/serif for brand only  
- Subtle spring/fade motion; haptics on key actions  
- Native patterns: NavigationStack, sheets, confirmationDialog, searchable, Dynamic Type  
- No purple neon, no glassmorphism spam, no emoji chrome  
- Brand **CON ANIMA** must read as hero on Login  

## Refactor rules

- One concern per change; don’t mix feature + rename mega-diffs  
- Methods short; extract repeated field/chip/metric UI into Components/  
- No dead code / debug leftovers in shipping UI (diagnostic errors OK behind clear copy)  
- Don’t change Go backend or `web2`  

## Constraints

- iOS 17+, SwiftUI, XcodeGen project in `/ios`  
- Prod API: `http://46.101.212.67:3000/api/v1`  
- Language of UI: Russian  
- Communicate with user in Russian, lite style  

## Progress checklist

- [x] Login  
- [x] Students  
- [x] StudentCard  
- [ ] Forms (Add/Edit/Renew)  
- [ ] History  
- [x] Journal (today + week)  
- [ ] Summary  
- [ ] Shell / polish pass  

## Current target

**Forms (Add/Edit/Renew)** — next.

## Journal — done

**Redesign:** remaining-lessons subtitle; primary stroke on «Сейчас» card; week auto-expands today/first busy day + «Сегодня» chip; bright systemBackground cards.

**Fixes:** removed timeline dots; dropped whole-card opacity (looked dull); pull-to-refresh no longer swaps to ProgressView over labels.

**Extracted:** `Views/Schedule/JournalView.swift` (JournalView + JournalTodayView). `StudentScheduleView` stays in `ScheduleViews.swift`.

**Logic preserved:** schedule load loops, HoldToAction complete, missed alert, handled state.

## Login — done (iteration 1)

**Bugs fixed:** submit disabled when empty; Return/Go keyboard submit; tap-to-dismiss keyboard; focus ring; network errors show host only (not dump full URL on wrong password).

**Redesign:** brand-first hero (note mark + CON ANIMA + subtitle), soft indigo wash, form card, ErrorCallout, appear spring, haptics.

**Extracted:** `Components/FormControls.swift` (`AppTextField`, `ErrorCallout`).

## Students — pet-link detail pattern (iteration 4)

Borrowed from Boxmind (`BookmarkRowView` / `BookmarkDetailView`):
- List rows navigate to **StudentDetailView**
- Detail: header + fact chips + progress + large CTAs (провести/пропуск) + secondary list (расписание/продлить/изменить) + toolbar menu delete
- Swipe-to-delete on list; chevron hidden
- Files: `StudentRowView`, `StudentDetailView`, `NavigationRoutes`
