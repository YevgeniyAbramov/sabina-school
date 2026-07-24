package handler

import (
	"fmt"
	"html"
	"os"
	"strconv"
	"strings"

	"sckool/middleware"
	"sckool/models"
	"sckool/service"

	"github.com/gofiber/fiber/v2"
)

type DiaryShareHandler struct {
	service *service.DiaryShareService
}

func NewDiaryShareHandler(service *service.DiaryShareService) *DiaryShareHandler {
	return &DiaryShareHandler{service: service}
}

type diaryShareCreateBody struct {
	DaysValid int `json:"days_valid"`
}

// Create POST /api/v1/student/:id/diary-share (auth)
func (h *DiaryShareHandler) Create(c *fiber.Ctx) error {
	teacherID := middleware.GetTeacherID(c)
	studentID, err := strconv.Atoi(c.Params("id"))
	if err != nil {
		return c.JSON(fiber.Map{"status": false, "message": "Некорректный id ученика"})
	}

	var body diaryShareCreateBody
	_ = c.BodyParser(&body)

	base := publicBaseURL(c)
	data, err := h.service.Create(c.Context(), studentID, teacherID, body.DaysValid, base)
	if err != nil {
		return c.JSON(fiber.Map{"status": false, "message": err.Error()})
	}
	return c.JSON(fiber.Map{"status": true, "message": "Ссылка создана", "data": data})
}

// PublicJSON GET /api/v1/public/diary/:token
func (h *DiaryShareHandler) PublicJSON(c *fiber.Ctx) error {
	view, err := h.service.ViewByToken(c.Context(), c.Params("token"), fileBaseURL(c))
	if err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"status":  false,
			"message": err.Error(),
		})
	}
	return c.JSON(fiber.Map{"status": true, "data": view})
}

// PublicPage GET /share/diary/:token — HTML for parents in the browser.
func (h *DiaryShareHandler) PublicPage(c *fiber.Ctx) error {
	view, err := h.service.ViewByToken(c.Context(), c.Params("token"), fileBaseURL(c))
	if err != nil {
		c.Set("Content-Type", "text/html; charset=utf-8")
		return c.Status(fiber.StatusNotFound).SendString(diaryShareErrorHTML(err.Error()))
	}
	c.Set("Content-Type", "text/html; charset=utf-8")
	return c.SendString(renderDiaryShareHTML(view))
}

func publicBaseURL(c *fiber.Ctx) string {
	if v := strings.TrimSpace(os.Getenv("PUBLIC_WEB_URL")); v != "" {
		return strings.TrimRight(v, "/")
	}
	scheme := c.Protocol()
	if fwd := c.Get("X-Forwarded-Proto"); fwd != "" {
		scheme = fwd
	}
	host := c.Get("X-Forwarded-Host")
	if host == "" {
		host = c.Hostname()
	}
	return scheme + "://" + host
}

func fileBaseURL(c *fiber.Ctx) string {
	return publicBaseURL(c)
}

func pieceStatusLabel(s models.PieceStatus) string {
	switch s {
	case models.PieceStatusPolished:
		return "Шлифует"
	case models.PieceStatusPaused:
		return "Пауза"
	case models.PieceStatusLearned:
		return "Выучил"
	default:
		return "Учит"
	}
}

func formatTenge(n int) string {
	s := fmt.Sprintf("%d", n)
	if n < 0 {
		s = s[1:]
	}
	var parts []string
	for len(s) > 3 {
		parts = append([]string{s[len(s)-3:]}, parts...)
		s = s[:len(s)-3]
	}
	parts = append([]string{s}, parts...)
	out := strings.Join(parts, " ")
	if n < 0 {
		return "-" + out + " ₸"
	}
	return out + " ₸"
}

func diaryShareErrorHTML(message string) string {
	msg := html.EscapeString(message)
	return `<!DOCTYPE html>
<html lang="ru">
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<title>CON ANIMA</title>
<style>
  body{margin:0;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif;background:#f4f6fb;color:#1c1f2a}
  .card{max-width:420px;margin:20vh auto;padding:28px;background:#fff;border-radius:20px;box-shadow:0 8px 30px rgba(28,31,42,.08);text-align:center}
  h1{font-size:1.15rem;margin:0 0 8px}
  p{margin:0;color:#6d7489;font-size:.95rem;line-height:1.45}
</style>
</head>
<body><div class="card"><h1>Ссылка не действует</h1><p>` + msg + `</p><p style="margin-top:12px">Попросите педагога прислать новую.</p></div></body>
</html>`
}

func renderDiaryShareHTML(view *models.PublicDiaryView) string {
	paidLabel := "Не оплачено"
	paidClass := "bad"
	if view.IsPaid {
		paidLabel = "Оплачено"
		paidClass = "ok"
	}

	learnedCount := 0
	for _, p := range view.Pieces {
		if p.Status == models.PieceStatusLearned {
			learnedCount++
		}
	}

	var b strings.Builder
	b.WriteString(`<!DOCTYPE html>
<html lang="ru">
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<meta name="robots" content="noindex,nofollow"/>
<title>`)
	b.WriteString(html.EscapeString(view.StudentName))
	b.WriteString(` — CON ANIMA</title>
<style>
  :root{
    --bg:#eef1f8;--card:#ffffff;--ink:#151822;--muted:#6b7285;--line:#e4e7f0;
    --primary:#4f6ef7;--primary-soft:#ebf0ff;--ok:#1f9d7a;--ok-soft:#e6f7f1;
    --warn:#c9851d;--warn-soft:#fff4e5;--bad:#d64545;--bad-soft:#fdecec;--amber:#d48a2e;
  }
  *{box-sizing:border-box}
  body{
    margin:0;
    font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif;
    color:var(--ink);
    line-height:1.45;
    background:
      radial-gradient(1200px 420px at 10% -10%, #dfe8ff 0%, transparent 55%),
      radial-gradient(900px 380px at 100% 0%, #f3e9ff 0%, transparent 50%),
      var(--bg);
  }
  .wrap{max-width:720px;margin:0 auto;padding:22px 16px 56px}
  .hero{
    background:linear-gradient(145deg,#ffffff 0%,#f4f7ff 100%);
    border:1px solid rgba(79,110,247,.12);
    border-radius:24px;
    padding:22px 20px 18px;
    box-shadow:0 10px 36px rgba(28,31,42,.07);
    margin-bottom:16px;
  }
  .brand{font-size:.7rem;font-weight:800;letter-spacing:.14em;color:var(--primary);margin:0 0 12px}
  h1{font-size:1.7rem;margin:0 0 8px;letter-spacing:-.03em;line-height:1.15}
  .meta{display:flex;flex-wrap:wrap;gap:8px;margin:0}
  .pill{
    display:inline-flex;align-items:center;gap:6px;
    padding:6px 11px;border-radius:999px;font-size:.78rem;font-weight:650;
    background:#f3f5fb;color:var(--muted);
  }
  .pill.ok{background:var(--ok-soft);color:var(--ok)}
  .pill.bad{background:var(--bad-soft);color:var(--bad)}
  .stats{
    display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:10px;
    margin:16px 0 0;
  }
  @media (min-width:560px){.stats{grid-template-columns:repeat(4,minmax(0,1fr))}}
  .stat{
    background:var(--card);border-radius:18px;padding:14px 12px;
    border:1px solid var(--line);box-shadow:0 4px 16px rgba(28,31,42,.04);
  }
  .stat .label{display:block;font-size:.72rem;font-weight:650;color:var(--muted);margin-bottom:6px}
  .stat .value{display:block;font-size:1.25rem;font-weight:800;letter-spacing:-.02em;font-variant-numeric:tabular-nums}
  .stat .hint{display:block;margin-top:2px;font-size:.72rem;color:var(--muted)}
  .section-title{
    display:flex;align-items:baseline;justify-content:space-between;gap:12px;
    margin:22px 4px 12px;
  }
  .section-title h2{margin:0;font-size:1.05rem;letter-spacing:-.01em}
  .section-title span{font-size:.8rem;color:var(--muted);font-weight:600}
  .piece{
    background:var(--card);border-radius:22px;padding:18px;
    margin-bottom:12px;border:1px solid rgba(228,231,240,.9);
    box-shadow:0 8px 28px rgba(28,31,42,.05);
  }
  .piece-top{display:flex;gap:14px;align-items:flex-start}
  .ring{
    width:62px;height:62px;border-radius:50%;flex:0 0 auto;
    display:grid;place-items:center;position:relative;
    background:conic-gradient(var(--primary) calc(var(--p)*1%),#e7ebf6 0);
  }
  .ring::after{content:"";position:absolute;inset:6px;border-radius:50%;background:#fff}
  .ring span{position:relative;z-index:1;font-weight:800;font-variant-numeric:tabular-nums;font-size:.88rem;color:var(--primary)}
  .piece h3{font-size:1.08rem;margin:0 0 4px;letter-spacing:-.01em}
  .composer{color:var(--muted);font-size:.9rem;margin:0 0 10px}
  .chip{
    display:inline-flex;align-items:center;padding:5px 10px;border-radius:999px;
    background:var(--primary-soft);color:var(--primary);font-size:.72rem;font-weight:750;
  }
  .chip.learned{background:var(--ok-soft);color:var(--ok)}
  .chip.paused{background:#f1f2f6;color:var(--muted)}
  .mats{margin-top:14px;display:grid;gap:8px}
  .mats-label{font-size:.72rem;font-weight:750;color:var(--muted);text-transform:uppercase;letter-spacing:.04em;margin:2px 2px 0}
  .mat{
    display:flex;gap:12px;align-items:center;text-decoration:none;color:inherit;
    padding:12px 12px;border-radius:16px;background:#f6f7fb;border:1px solid transparent;
  }
  .mat:active,.mat:hover{background:var(--primary-soft);border-color:rgba(79,110,247,.18)}
  .mat .icon{
    width:40px;height:40px;border-radius:12px;display:grid;place-items:center;
    flex:0 0 auto;font-size:.72rem;font-weight:800;
  }
  .mat.link .icon{background:#e8eeff;color:var(--primary)}
  .mat.file .icon{background:#fff1e0;color:var(--amber)}
  .mat .title{font-weight:700;font-size:.95rem}
  .mat .meta{color:var(--muted);font-size:.75rem;margin-top:2px;word-break:break-all}
  .empty{
    color:var(--muted);font-size:.92rem;padding:16px;text-align:center;
    background:#f7f8fc;border-radius:18px;border:1px dashed var(--line);
  }
  .foot{
    margin-top:28px;text-align:center;color:var(--muted);font-size:.78rem;
    display:grid;gap:4px;
  }
</style>
</head>
<body>
<div class="wrap">
  <header class="hero">
    <p class="brand">CON ANIMA</p>
    <h1>`)
	b.WriteString(html.EscapeString(view.StudentName))
	b.WriteString(`</h1>
    <div class="meta">
      <span class="pill">Дневник ученика</span>
      <span class="pill">Только просмотр</span>
      <span class="pill">До `)
	b.WriteString(html.EscapeString(view.ExpiresAt.Local().Format("02.01.2006")))
	b.WriteString(`</span>
      <span class="pill `)
	b.WriteString(paidClass)
	b.WriteString(`">`)
	b.WriteString(html.EscapeString(paidLabel))
	b.WriteString(`</span>
    </div>
    <div class="stats">
      <div class="stat">
        <span class="label">Пройдено</span>
        <span class="value">`)
	b.WriteString(fmt.Sprintf("%d", view.CompletedLessons))
	b.WriteString(`</span>
        <span class="hint">из `)
	b.WriteString(fmt.Sprintf("%d", view.TotalLessons))
	b.WriteString(` уроков</span>
      </div>
      <div class="stat">
        <span class="label">Осталось</span>
        <span class="value">`)
	b.WriteString(fmt.Sprintf("%d", view.RemainingLessons))
	b.WriteString(`</span>
        <span class="hint">уроков</span>
      </div>
      <div class="stat">
        <span class="label">Пропуски</span>
        <span class="value">`)
	b.WriteString(fmt.Sprintf("%d", view.MissedClasses))
	b.WriteString(`</span>
        <span class="hint">`)
	if view.MissedClasses == 0 {
		b.WriteString(`нет пропусков`)
	} else {
		b.WriteString(`за период`)
	}
	b.WriteString(`</span>
      </div>
      <div class="stat">
        <span class="label">Оплата</span>
        <span class="value" style="font-size:1.05rem">`)
	b.WriteString(html.EscapeString(formatTenge(view.PaidAmount)))
	b.WriteString(`</span>
        <span class="hint">`)
	b.WriteString(html.EscapeString(paidLabel))
	b.WriteString(`</span>
      </div>
    </div>
  </header>

  <div class="section-title">
    <h2>Репертуар</h2>
    <span>`)
	b.WriteString(fmt.Sprintf("%d произв.", len(view.Pieces)))
	if learnedCount > 0 {
		b.WriteString(fmt.Sprintf(", выучено %d", learnedCount))
	}
	b.WriteString(`</span>
  </div>
`)

	if len(view.Pieces) == 0 {
		b.WriteString(`<div class="empty">Пока нет произведений в репертуаре</div>`)
	}

	for _, p := range view.Pieces {
		chipClass := "chip"
		switch p.Status {
		case models.PieceStatusLearned:
			chipClass = "chip learned"
		case models.PieceStatusPaused:
			chipClass = "chip paused"
		}

		b.WriteString(`<article class="piece">
  <div class="piece-top">
    <div class="ring" style="--p:`)
		b.WriteString(fmt.Sprintf("%d", p.Readiness))
		b.WriteString(`"><span>`)
		b.WriteString(fmt.Sprintf("%d%%", p.Readiness))
		b.WriteString(`</span></div>
    <div>
      <h3>`)
		b.WriteString(html.EscapeString(p.Title))
		b.WriteString(`</h3>`)
		if strings.TrimSpace(p.Composer) != "" {
			b.WriteString(`<p class="composer">`)
			b.WriteString(html.EscapeString(p.Composer))
			b.WriteString(`</p>`)
		} else {
			b.WriteString(`<p class="composer">Композитор не указан</p>`)
		}
		b.WriteString(`<span class="`)
		b.WriteString(chipClass)
		b.WriteString(`">`)
		b.WriteString(html.EscapeString(pieceStatusLabel(p.Status)))
		b.WriteString(`</span>
    </div>
  </div>
`)
		if len(p.Materials) == 0 {
			b.WriteString(`<p class="empty" style="margin-top:14px">Ноты и ссылки пока не добавлены</p>`)
		} else {
			b.WriteString(`<div class="mats"><div class="mats-label">Материалы</div>`)
			for _, m := range p.Materials {
				kindClass := "file"
				icon := "PDF"
				lowerURL := strings.ToLower(m.URL)
				if m.Kind == models.MaterialKindLink {
					kindClass = "link"
					icon = "URL"
				} else if strings.Contains(lowerURL, ".png") ||
					strings.Contains(lowerURL, ".jpg") ||
					strings.Contains(lowerURL, ".jpeg") ||
					strings.Contains(lowerURL, ".heic") {
					icon = "IMG"
				}
				href := html.EscapeString(m.URL)
				title := html.EscapeString(m.Title)
				meta := ""
				if m.Kind == models.MaterialKindLink {
					meta = html.EscapeString(m.URL)
				} else if strings.TrimSpace(m.Note) != "" {
					meta = html.EscapeString(m.Note)
				} else {
					meta = "Открыть файл"
				}
				if href == "" {
					b.WriteString(`<div class="mat ` + kindClass + `"><div class="icon">` + icon + `</div><div><div class="title">` + title + `</div>`)
					if meta != "" {
						b.WriteString(`<div class="meta">` + meta + `</div>`)
					}
					b.WriteString(`</div></div>`)
					continue
				}
				b.WriteString(`<a class="mat ` + kindClass + `" href="` + href + `" target="_blank" rel="noopener noreferrer"><div class="icon">` + icon + `</div><div><div class="title">` + title + `</div>`)
				if meta != "" {
					b.WriteString(`<div class="meta">` + meta + `</div>`)
				}
				b.WriteString(`</div></a>`)
			}
			b.WriteString(`</div>`)
		}
		b.WriteString(`</article>`)
	}

	b.WriteString(`
  <footer class="foot">
    <div>CON ANIMA</div>
    <div>Страница обновляется при открытии ссылки</div>
  </footer>
</div>
</body>
</html>`)
	return b.String()
}
