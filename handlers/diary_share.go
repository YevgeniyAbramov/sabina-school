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
  :root{--bg:#f3f5fb;--card:#fff;--ink:#1c1f2a;--muted:#6d7489;--line:#e6e8ef;--primary:#5b7cfa;--primary-soft:#eef2ff;--amber:#d48a2e}
  *{box-sizing:border-box}
  body{margin:0;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif;background:linear-gradient(180deg,#eef2ff 0%,var(--bg) 180px);color:var(--ink);line-height:1.45}
  .wrap{max-width:720px;margin:0 auto;padding:24px 16px 48px}
  .brand{font-size:.72rem;font-weight:700;letter-spacing:.12em;color:var(--primary);margin-bottom:10px}
  h1{font-size:1.65rem;margin:0 0 6px;letter-spacing:-.02em}
  .sub{color:var(--muted);font-size:.95rem;margin:0 0 22px}
  .piece{background:var(--card);border-radius:20px;padding:18px 18px 14px;margin-bottom:14px;box-shadow:0 6px 24px rgba(28,31,42,.06)}
  .piece-top{display:flex;gap:14px;align-items:flex-start}
  .ring{width:56px;height:56px;border-radius:50%;display:grid;place-items:center;flex:0 0 auto;background:conic-gradient(var(--primary) calc(var(--p)*1%),#e8ecf8 0);position:relative}
  .ring::after{content:"";position:absolute;inset:5px;border-radius:50%;background:#fff}
  .ring span{position:relative;z-index:1;font-weight:700;font-variant-numeric:tabular-nums;font-size:.85rem;color:var(--primary)}
  .piece h2{font-size:1.1rem;margin:0 0 4px}
  .composer{color:var(--muted);font-size:.9rem;margin:0 0 8px}
  .chip{display:inline-flex;align-items:center;padding:4px 10px;border-radius:999px;background:var(--primary-soft);color:var(--primary);font-size:.72rem;font-weight:700}
  .mats{margin-top:14px;border-top:1px solid var(--line);padding-top:10px;display:grid;gap:8px}
  .mat{display:flex;gap:10px;align-items:flex-start;text-decoration:none;color:inherit;padding:10px 12px;border-radius:14px;background:#f7f8fc}
  .mat:hover{background:var(--primary-soft)}
  .mat .icon{width:36px;height:36px;border-radius:10px;display:grid;place-items:center;flex:0 0 auto;font-size:.75rem;font-weight:700}
  .mat.link .icon{background:#e8eeff;color:var(--primary)}
  .mat.file .icon{background:#fff1e0;color:var(--amber)}
  .mat .title{font-weight:600;font-size:.95rem}
  .mat .meta{color:var(--muted);font-size:.78rem;margin-top:2px;word-break:break-all}
  .empty{color:var(--muted);font-size:.9rem;padding:8px 2px}
  .foot{margin-top:22px;text-align:center;color:var(--muted);font-size:.8rem}
</style>
</head>
<body>
<div class="wrap">
  <div class="brand">CON ANIMA</div>
  <h1>`)
	b.WriteString(html.EscapeString(view.StudentName))
	b.WriteString(`</h1>
  <p class="sub">Дневник ученика · только просмотр · до `)
	b.WriteString(html.EscapeString(view.ExpiresAt.Local().Format("02.01.2006")))
	b.WriteString(`</p>
`)

	if len(view.Pieces) == 0 {
		b.WriteString(`<div class="piece"><p class="empty">Пока нет произведений в репертуаре.</p></div>`)
	}

	for _, p := range view.Pieces {
		b.WriteString(`<article class="piece">
  <div class="piece-top">
    <div class="ring" style="--p:`)
		b.WriteString(fmt.Sprintf("%d", p.Readiness))
		b.WriteString(`"><span>`)
		b.WriteString(fmt.Sprintf("%d%%", p.Readiness))
		b.WriteString(`</span></div>
    <div>
      <h2>`)
		b.WriteString(html.EscapeString(p.Title))
		b.WriteString(`</h2>`)
		if strings.TrimSpace(p.Composer) != "" {
			b.WriteString(`<p class="composer">`)
			b.WriteString(html.EscapeString(p.Composer))
			b.WriteString(`</p>`)
		}
		b.WriteString(`<span class="chip">`)
		b.WriteString(html.EscapeString(pieceStatusLabel(p.Status)))
		b.WriteString(`</span>
    </div>
  </div>
`)
		if len(p.Materials) == 0 {
			b.WriteString(`<p class="empty">Материалов пока нет</p>`)
		} else {
			b.WriteString(`<div class="mats">`)
			for _, m := range p.Materials {
				kindClass := "file"
				icon := "PDF"
				lowerURL := strings.ToLower(m.URL)
				if m.Kind == models.MaterialKindLink {
					kindClass = "link"
					icon = "▶"
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
  <p class="foot">CON ANIMA · страница обновляется при открытии ссылки</p>
</div>
</body>
</html>`)
	return b.String()
}
