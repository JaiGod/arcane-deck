extends RefCounted
## Arcane Deck - every picture in the game is drawn here with code:
## card motifs, card frames, heroes, enemies, intents, relics and map icons.

const C := preload("res://scripts/cards.gd")
const D := preload("res://scripts/data.gd")

const TYPE_COL := [Color("e0573f"), Color("3f8fe0"), Color("e0b23f"), Color("6a5a7a")]
const RAR_COL := [Color("9a92a8"), Color("cfd6e6"), Color("6be0ff"), Color("ffcf4a"), Color("d8a8ff")]
const INK := Color("1a1424")
const PAPER := Color("f4ead8")


static func font() -> Font:
	return ThemeDB.fallback_font


static func star_pts(c: Vector2, r1: float, r2: float, n: int, rot := -PI / 2) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n * 2:
		var a := rot + i * PI / n
		pts.append(c + Vector2(cos(a), sin(a)) * (r1 if i % 2 == 0 else r2))
	return pts


static func ngon(c: Vector2, r: float, n: int, rot := 0.0, sx := 1.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := rot + TAU * i / n
		pts.append(c + Vector2(cos(a) * r * sx, sin(a) * r))
	return pts


static func text(ci: CanvasItem, pos: Vector2, s: String, size: int, col: Color, align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0, outline := 0) -> void:
	var f := font()
	if outline > 0:
		ci.draw_string_outline(f, pos, s, align, width, size, outline, Color(0, 0, 0, 0.75 * col.a))
	ci.draw_string(f, pos, s, align, width, size, col)


static func text_c(ci: CanvasItem, center: Vector2, s: String, size: int, col: Color, outline := 0) -> void:
	var f := font()
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	text(ci, Vector2(center.x - w / 2, center.y + size * 0.35), s, size, col, HORIZONTAL_ALIGNMENT_LEFT, -1, outline)


static func para(ci: CanvasItem, pos: Vector2, s: String, size: int, col: Color, width: float, align := HORIZONTAL_ALIGNMENT_CENTER, max_lines := -1) -> void:
	ci.draw_multiline_string(font(), pos + Vector2(0, size), s, align, width, size, max_lines, col)


static func panel(ci: CanvasItem, r: Rect2, bg: Color, border: Color, rad := 12.0, bw := 2.0) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(int(bw))
	sb.set_corner_radius_all(int(rad))
	sb.anti_aliasing = true
	ci.draw_style_box(sb, r)


static func glow_circle(ci: CanvasItem, c: Vector2, r: float, col: Color, steps := 5) -> void:
	for i in steps:
		var k := 1.0 - float(i) / steps
		ci.draw_circle(c, r * (0.4 + 0.6 * k), Color(col.r, col.g, col.b, col.a * 0.16))


# ------------------------------------------------------------ motifs

static func motif(ci: CanvasItem, m: String, c: Vector2, s: float, col: Color, t := 0.0) -> void:
	var dark := col.darkened(0.55)
	var lite := col.lightened(0.45)
	var w := maxf(2.0, s * 0.07)
	match m:
		"fist":
			ci.draw_rect(Rect2(c + Vector2(-s * 0.32, -s * 0.18), Vector2(s * 0.64, s * 0.5)), col)
			for i in 4:
				ci.draw_circle(c + Vector2(-s * 0.24 + i * s * 0.16, -s * 0.2), s * 0.1, lite)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.2, s * 0.32), Vector2(s * 0.4, s * 0.2)), dark)
			ci.draw_line(c + Vector2(-s * 0.32, s * 0.05), c + Vector2(s * 0.1, s * 0.05), dark, w)
		"shield":
			var pts := PackedVector2Array([c + Vector2(0, -s * 0.45), c + Vector2(s * 0.38, -s * 0.3), c + Vector2(s * 0.32, s * 0.12), c + Vector2(0, s * 0.48), c + Vector2(-s * 0.32, s * 0.12), c + Vector2(-s * 0.38, -s * 0.3)])
			ci.draw_colored_polygon(pts, col)
			var inner := PackedVector2Array()
			for p in pts:
				inner.append(c + (p - c) * 0.62)
			ci.draw_colored_polygon(inner, lite)
			ci.draw_line(c + Vector2(0, -s * 0.28), c + Vector2(0, s * 0.3), dark, w)
		"burst":
			ci.draw_colored_polygon(star_pts(c, s * 0.48, s * 0.2, 8, t * 0.5), col)
			ci.draw_colored_polygon(star_pts(c, s * 0.26, s * 0.12, 8, t * 0.5 + 0.4), lite)
		"blade":
			var pts := PackedVector2Array([c + Vector2(-s * 0.05, s * 0.2), c + Vector2(s * 0.34, -s * 0.42), c + Vector2(s * 0.4, -s * 0.36), c + Vector2(s * 0.05, s * 0.28)])
			ci.draw_colored_polygon(pts, lite)
			ci.draw_line(c + Vector2(-s * 0.2, s * 0.1), c + Vector2(s * 0.12, s * 0.38), col, w * 1.6)
			ci.draw_line(c + Vector2(-s * 0.02, s * 0.25), c + Vector2(-s * 0.3, s * 0.45), dark, w * 1.8)
		"mountain":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.48, s * 0.38), c + Vector2(-s * 0.1, -s * 0.36), c + Vector2(s * 0.12, s * 0.0), c + Vector2(s * 0.24, -s * 0.16), c + Vector2(s * 0.48, s * 0.38)]), col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.22, -s * 0.12), c + Vector2(-s * 0.1, -s * 0.36), c + Vector2(s * 0.02, -s * 0.14)]), lite)
		"gear":
			ci.draw_colored_polygon(star_pts(c, s * 0.44, s * 0.34, 8, t * 0.6), col)
			ci.draw_circle(c, s * 0.2, dark)
			ci.draw_circle(c, s * 0.1, lite)
		"flame":
			var f := 1.0 + sin(t * 6.0) * 0.06
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s * 0.48 * f), c + Vector2(s * 0.3, -s * 0.05), c + Vector2(s * 0.26, s * 0.3), c + Vector2(0, s * 0.44), c + Vector2(-s * 0.26, s * 0.3), c + Vector2(-s * 0.3, -s * 0.05), c + Vector2(-s * 0.08, -s * 0.2)]), col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s * 0.15 * f), c + Vector2(s * 0.15, s * 0.15), c + Vector2(0, s * 0.36), c + Vector2(-s * 0.15, s * 0.15)]), lite)
		"fang":
			for i in 3:
				var x := (i - 1) * s * 0.26
				ci.draw_colored_polygon(PackedVector2Array([c + Vector2(x - s * 0.12, -s * 0.36), c + Vector2(x + s * 0.12, -s * 0.36), c + Vector2(x, s * 0.4 - abs(i - 1) * s * 0.14)]), lite if i == 1 else col)
		"crown":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.42, s * 0.3), c + Vector2(-s * 0.42, -s * 0.28), c + Vector2(-s * 0.2, 0), c + Vector2(0, -s * 0.4), c + Vector2(s * 0.2, 0), c + Vector2(s * 0.42, -s * 0.28), c + Vector2(s * 0.42, s * 0.3)]), col)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.42, s * 0.18), Vector2(s * 0.84, s * 0.12)), dark)
			ci.draw_circle(c + Vector2(0, s * 0.05), s * 0.07, lite)
		"heart":
			ci.draw_circle(c + Vector2(-s * 0.18, -s * 0.1), s * 0.22, col)
			ci.draw_circle(c + Vector2(s * 0.18, -s * 0.1), s * 0.22, col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.39, -s * 0.03), c + Vector2(s * 0.39, -s * 0.03), c + Vector2(0, s * 0.42)]), col)
			ci.draw_circle(c + Vector2(-s * 0.2, -s * 0.16), s * 0.07, lite)
		"orb":
			glow_circle(ci, c, s * 0.5, lite)
			ci.draw_circle(c, s * 0.3, col)
			ci.draw_arc(c, s * 0.42, t, t + PI * 1.2, 24, lite, w)
			ci.draw_circle(c + Vector2(-s * 0.1, -s * 0.1), s * 0.08, lite)
		"cyclone", "spiral":
			var pts := PackedVector2Array()
			for i in 40:
				var a := t * (1.5 if m == "cyclone" else 0.6) + i * 0.36
				pts.append(c + Vector2(cos(a), sin(a)) * s * 0.46 * (1.0 - i / 44.0))
			ci.draw_polyline(pts, col, w * 1.3, true)
			ci.draw_circle(c, s * 0.08, lite)
		"leaf":
			var pts := PackedVector2Array()
			for i in 17:
				var k := i / 16.0
				pts.append(c + Vector2(sin(k * PI) * s * 0.26, -s * 0.44 + k * s * 0.84).rotated(0.5))
			for i in 17:
				var k := 1.0 - i / 16.0
				pts.append(c + Vector2(-sin(k * PI) * s * 0.26, -s * 0.44 + k * s * 0.84).rotated(0.5))
			ci.draw_colored_polygon(pts, col)
			ci.draw_line(c + Vector2(0, -s * 0.4).rotated(0.5), c + Vector2(0, s * 0.46).rotated(0.5), dark, w)
		"drop":
			ci.draw_circle(c + Vector2(0, s * 0.12), s * 0.28, col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s * 0.46), c + Vector2(s * 0.26, s * 0.04), c + Vector2(-s * 0.26, s * 0.04)]), col)
			ci.draw_circle(c + Vector2(-s * 0.1, s * 0.06), s * 0.07, lite)
		"moon":
			ci.draw_circle(c, s * 0.4, col)
			ci.draw_circle(c + Vector2(s * 0.18, -s * 0.12), s * 0.34, dark)
			ci.draw_circle(c + Vector2(-s * 0.2, s * 0.12), s * 0.05, lite)
		"skull":
			ci.draw_circle(c + Vector2(0, -s * 0.06), s * 0.34, col)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.2, s * 0.14), Vector2(s * 0.4, s * 0.24)), col)
			ci.draw_circle(c + Vector2(-s * 0.13, -s * 0.06), s * 0.09, dark)
			ci.draw_circle(c + Vector2(s * 0.13, -s * 0.06), s * 0.09, dark)
			for i in 3:
				ci.draw_line(c + Vector2(-s * 0.1 + i * s * 0.1, s * 0.24), c + Vector2(-s * 0.1 + i * s * 0.1, s * 0.38), dark, w * 0.7)
		"wave":
			for k in 3:
				var pts := PackedVector2Array()
				for i in 21:
					var x := -s * 0.45 + i * s * 0.045
					pts.append(c + Vector2(x, (k - 1) * s * 0.24 + sin(i * 0.6 + t * 3 + k) * s * 0.07))
				ci.draw_polyline(pts, col if k != 1 else lite, w * 1.2, true)
		"star":
			ci.draw_colored_polygon(star_pts(c, s * 0.48, s * 0.2, 5, -PI / 2 + sin(t) * 0.1), col)
			ci.draw_colored_polygon(star_pts(c, s * 0.22, s * 0.09, 5, -PI / 2 + sin(t) * 0.1), lite)
		"bolt":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(s * 0.1, -s * 0.48), c + Vector2(s * 0.24, -s * 0.48), c + Vector2(s * 0.06, -s * 0.06), c + Vector2(s * 0.26, -s * 0.06), c + Vector2(-s * 0.16, s * 0.48), c + Vector2(-s * 0.02, s * 0.06), c + Vector2(-s * 0.22, s * 0.06)]), col)
		"comet":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(s * 0.24, -s * 0.12), c + Vector2(-s * 0.46, s * 0.46), c + Vector2(s * 0.08, -s * 0.3)]), Color(col, 0.6))
			ci.draw_circle(c + Vector2(s * 0.2, -s * 0.24), s * 0.18, col)
			ci.draw_circle(c + Vector2(s * 0.16, -s * 0.28), s * 0.07, lite)
		"rune":
			ci.draw_colored_polygon(ngon(c, s * 0.44, 6, t * 0.2), dark)
			ci.draw_polyline(PackedVector2Array([c + Vector2(-s * 0.16, -s * 0.3), c + Vector2(s * 0.14, -s * 0.02), c + Vector2(-s * 0.16, s * 0.1), c + Vector2(s * 0.14, s * 0.32)]), lite, w * 1.3)
			ci.draw_line(c + Vector2(0, -s * 0.34), c + Vector2(0, s * 0.34), col, w)
		"eye":
			var pts := PackedVector2Array()
			for i in 16:
				var a := PI * i / 15.0
				pts.append(c + Vector2(-cos(a) * s * 0.46, -sin(a) * s * 0.26))
			for i in 16:
				var a := PI * i / 15.0
				pts.append(c + Vector2(cos(a) * s * 0.46, sin(a) * s * 0.26))
			ci.draw_colored_polygon(pts, lite)
			ci.draw_circle(c + Vector2(sin(t) * s * 0.06, 0), s * 0.18, col)
			ci.draw_circle(c + Vector2(sin(t) * s * 0.06, 0), s * 0.08, INK)
		_:
			ci.draw_circle(c, s * 0.3, col)


# ------------------------------------------------------------ cards

static func card_size(big := false) -> Vector2:
	return Vector2(200, 280) if big else Vector2(150, 210)


## Draws a card with its top-left at `pos`.
static func card(ci: CanvasItem, pos: Vector2, id: String, up: bool, t := 0.0, sz := Vector2(150, 210), playable := true, str_b := 0, sapped := false, highlight := false) -> void:
	var cd := C.card(id)
	var k := sz.x / 150.0
	var tc: Color = TYPE_COL[cd["t"]]
	var hero: int = cd["h"]
	var hc: Color = C.HEROES[hero]["col"] if hero >= 0 else Color("c8b0ff")
	var r := Rect2(pos, sz)
	if highlight:
		panel(ci, r.grow(6 * k), Color(1, 0.9, 0.4, 0.35), Color(1, 0.9, 0.5, 0.9), 16 * k, 3)
	ci.draw_rect(Rect2(pos + Vector2(5, 7) * k, sz), Color(0, 0, 0, 0.35))
	panel(ci, r, tc.darkened(0.55), RAR_COL[cd["r"]] if not up else Color("8cff9a"), 12 * k, 3 * k)
	# art window
	var art := Rect2(pos + Vector2(10, 32) * k, Vector2(130, 78) * k)
	panel(ci, art, hc.darkened(0.7), tc.darkened(0.2), 8 * k, 2)
	var ac := art.get_center()
	glow_circle(ci, ac, 34 * k, hc)
	motif(ci, cd["art"], ac, 58 * k, hc.lightened(0.15), t)
	# name banner
	var nm := C.display_name(id, up)
	var fs := int(15 * k) if nm.length() < 14 else int(13 * k)
	text_c(ci, pos + Vector2(sz.x / 2 + 8 * k, 18 * k), nm, fs, Color("8cff9a") if up else PAPER, 2)
	# cost gem
	var cost := C.cost_of(id, up)
	if cost >= 0:
		var gc := pos + Vector2(8, 8) * k
		ci.draw_colored_polygon(ngon(gc, 17 * k, 6, PI / 6), Color("2a1a4a"))
		ci.draw_colored_polygon(ngon(gc, 14 * k, 6, PI / 6), Color("ffcf4a") if playable else Color("6a6070"))
		text_c(ci, gc, str(cost), int(18 * k), INK if playable else Color("d0c8d8"))
	# type line
	text_c(ci, pos + Vector2(sz.x / 2, 120 * k), C.TYPE_NAMES[cd["t"]] + ("  -  " + C.RARITY_NAMES[cd["r"]] if cd["r"] > 0 and cd["r"] < 4 else ""), int(10 * k), tc.lightened(0.5))
	# rules text
	panel(ci, Rect2(pos + Vector2(9, 129) * k, Vector2(132, 72) * k), Color(0.96, 0.92, 0.85, 0.95), tc.darkened(0.3), 6 * k, 1)
	var tx := C.text(id, up, str_b, sapped)
	var lines := tx.count("\n") + 1
	var tfs := int((12.5 if lines <= 3 and tx.length() < 70 else 11) * k)
	para(ci, pos + Vector2(12, 132 + (2 if lines < 3 else 0)) * k, tx, tfs, INK, 126 * k, HORIZONTAL_ALIGNMENT_CENTER, 5)


static func card_back(ci: CanvasItem, pos: Vector2, sz: Vector2, col: Color) -> void:
	panel(ci, Rect2(pos, sz), col.darkened(0.7), col, 8, 2)
	motif(ci, "rune", pos + sz / 2, sz.x * 0.6, col)


# ------------------------------------------------------------ heroes

static func hero(ci: CanvasItem, h: int, c: Vector2, s: float, t: float, flash := 0.0) -> void:
	var hd: Dictionary = C.HEROES[h]
	var col: Color = hd["col"]
	var col2: Color = hd["col2"]
	var glow: Color = hd["glow"]
	if flash > 0:
		col = col.lerp(Color.WHITE, flash)
		col2 = col2.lerp(Color.WHITE, flash)
	var bob := sin(t * 2.0) * s * 0.02
	var sh := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20
		sh.append(c + Vector2(cos(a) * s * 0.34, s * 0.5 + sin(a) * s * 0.07))
	ci.draw_colored_polygon(sh, Color(0, 0, 0, 0.35))
	var b := c + Vector2(0, bob)
	match h:
		0: # armored knight
			ci.draw_colored_polygon(PackedVector2Array([b + Vector2(-s * 0.26, s * 0.48), b + Vector2(-s * 0.3, -s * 0.05), b + Vector2(s * 0.3, -s * 0.05), b + Vector2(s * 0.26, s * 0.48)]), col2)
			ci.draw_rect(Rect2(b + Vector2(-s * 0.32, -s * 0.12), Vector2(s * 0.64, s * 0.34)), col)
			ci.draw_circle(b + Vector2(-s * 0.32, -s * 0.06), s * 0.12, col.lightened(0.2))
			ci.draw_circle(b + Vector2(s * 0.32, -s * 0.06), s * 0.12, col.lightened(0.2))
			ci.draw_circle(b + Vector2(0, -s * 0.28), s * 0.17, col.darkened(0.2))
			ci.draw_rect(Rect2(b + Vector2(-s * 0.12, -s * 0.31), Vector2(s * 0.24, s * 0.05)), INK)
			ci.draw_circle(b + Vector2(-s * 0.05, -s * 0.285), s * 0.02, glow)
			ci.draw_circle(b + Vector2(s * 0.05, -s * 0.285), s * 0.02, glow)
			# hammer
			ci.draw_line(b + Vector2(s * 0.4, s * 0.3), b + Vector2(s * 0.48, -s * 0.36), Color("6a4a2a"), s * 0.05)
			ci.draw_rect(Rect2(b + Vector2(s * 0.34, -s * 0.5), Vector2(s * 0.3, s * 0.18)), Color("b8b0c0"))
			# shield
			motif(ci, "shield", b + Vector2(-s * 0.36, s * 0.14), s * 0.42, col.lightened(0.1), t)
		1: # witch
			ci.draw_colored_polygon(PackedVector2Array([b + Vector2(-s * 0.34, s * 0.5), b + Vector2(0, -s * 0.18), b + Vector2(s * 0.34, s * 0.5)]), col2)
			ci.draw_circle(b + Vector2(0, -s * 0.2), s * 0.14, Color("e8d2c0").lerp(Color.WHITE, flash))
			ci.draw_colored_polygon(PackedVector2Array([b + Vector2(-s * 0.3, -s * 0.24), b + Vector2(s * 0.3, -s * 0.24), b + Vector2(s * 0.12, -s * 0.5), b + Vector2(s * 0.28, -s * 0.68), b + Vector2(s * 0.02, -s * 0.56)]), col2.lightened(0.15))
			ci.draw_circle(b + Vector2(-s * 0.05, -s * 0.19), s * 0.025, col)
			ci.draw_circle(b + Vector2(s * 0.05, -s * 0.19), s * 0.025, col)
			for i in 5:
				ci.draw_line(b + Vector2(-s * 0.3 + i * s * 0.15, s * 0.5), b + Vector2(-s * 0.32 + i * s * 0.15, s * 0.36), col, s * 0.03)
			ci.draw_line(b + Vector2(s * 0.32, s * 0.48), b + Vector2(s * 0.36, -s * 0.36), Color("5a3a1a"), s * 0.04)
			glow_circle(ci, b + Vector2(s * 0.36, -s * 0.4), s * 0.12, glow)
			motif(ci, "leaf", b + Vector2(s * 0.36, -s * 0.4), s * 0.16, col, t)
		_: # star sage
			ci.draw_colored_polygon(PackedVector2Array([b + Vector2(-s * 0.3, s * 0.5), b + Vector2(-s * 0.18, -s * 0.12), b + Vector2(s * 0.18, -s * 0.12), b + Vector2(s * 0.3, s * 0.5)]), col2)
			for i in 6:
				ci.draw_circle(b + Vector2(-s * 0.18 + (i % 3) * s * 0.18, s * 0.1 + (i / 3) * s * 0.2), s * 0.02, glow)
			ci.draw_circle(b + Vector2(0, -s * 0.24), s * 0.14, col2.lightened(0.2))
			ci.draw_circle(b + Vector2(0, -s * 0.22), s * 0.1, INK)
			ci.draw_circle(b + Vector2(-s * 0.04, -s * 0.23), s * 0.02, glow)
			ci.draw_circle(b + Vector2(s * 0.04, -s * 0.23), s * 0.02, glow)
			for i in 3:
				var a := t * 1.4 + i * TAU / 3
				var op := b + Vector2(cos(a) * s * 0.42, -s * 0.05 + sin(a) * s * 0.14)
				glow_circle(ci, op, s * 0.07, col)
				ci.draw_circle(op, s * 0.035, glow)
			ci.draw_arc(b + Vector2(0, -s * 0.05), s * 0.42, 0, TAU, 32, Color(col, 0.25), 1.5)


# ------------------------------------------------------------ enemies

static func enemy(ci: CanvasItem, id: String, c: Vector2, t: float, flash := 0.0, hp_frac := 1.0) -> void:
	var e: Dictionary = D.ENEMIES[id]
	var s: float = 120.0 * e["sz"]
	var col: Color = e["col"]
	var col2: Color = e["col2"]
	if flash > 0:
		col = col.lerp(Color.WHITE, flash)
		col2 = col2.lerp(Color.WHITE, flash * 0.8)
	var eye := Color("fff3a0")
	var sh := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20
		sh.append(c + Vector2(cos(a) * s * 0.4, s * 0.5 + sin(a) * s * 0.08))
	ci.draw_colored_polygon(sh, Color(0, 0, 0, 0.35))
	var bob := sin(t * 2.3 + c.x * 0.01) * s * 0.03
	var b := c + Vector2(0, bob)
	match e["shape"]:
		"blob":
			var pts := PackedVector2Array()
			for i in 24:
				var a := PI + PI * i / 23.0
				pts.append(b + Vector2(cos(a) * s * 0.42, s * 0.48 + sin(a) * s * (0.7 + sin(t * 3) * 0.03)))
			ci.draw_colored_polygon(pts, col)
			ci.draw_circle(b + Vector2(-s * 0.14, -s * 0.02), s * 0.08, eye)
			ci.draw_circle(b + Vector2(s * 0.12, -s * 0.06), s * 0.06, eye)
			ci.draw_arc(b + Vector2(0, s * 0.18), s * 0.16, 0.2, PI - 0.2, 12, col2, s * 0.04)
		"puff":
			for i in 6:
				var a := TAU * i / 6 + t * 0.4
				ci.draw_circle(b + Vector2(cos(a), sin(a)) * s * 0.2 + Vector2(0, s * 0.1), s * 0.2, col.darkened(0.1 * (i % 2)))
			ci.draw_circle(b + Vector2(0, s * 0.1), s * 0.24, col.lightened(0.15))
			ci.draw_circle(b + Vector2(-s * 0.08, s * 0.06), s * 0.04, INK)
			ci.draw_circle(b + Vector2(s * 0.08, s * 0.06), s * 0.04, INK)
		"bug":
			for i in 3:
				ci.draw_line(b + Vector2(-s * 0.2, s * 0.2 + i * s * 0.1), b + Vector2(-s * 0.46, s * 0.3 + i * s * 0.12), col2, s * 0.04)
				ci.draw_line(b + Vector2(s * 0.2, s * 0.2 + i * s * 0.1), b + Vector2(s * 0.46, s * 0.3 + i * s * 0.12), col2, s * 0.04)
			ci.draw_colored_polygon(ngon(b + Vector2(0, s * 0.2), s * 0.32, 18, 0, 1.15), col)
			ci.draw_line(b + Vector2(0, -s * 0.1), b + Vector2(0, s * 0.5), col2, s * 0.03)
			ci.draw_circle(b + Vector2(0, -s * 0.12), s * 0.16, col2)
			ci.draw_circle(b + Vector2(-s * 0.06, -s * 0.15), s * 0.035, eye)
			ci.draw_circle(b + Vector2(s * 0.06, -s * 0.15), s * 0.035, eye)
		"beast":
			ci.draw_colored_polygon(ngon(b + Vector2(0, s * 0.18), s * 0.32, 16, 0, 1.4), col)
			for i in 4:
				ci.draw_rect(Rect2(b + Vector2(-s * 0.36 + i * s * 0.22, s * 0.3), Vector2(s * 0.08, s * 0.2)), col2)
			ci.draw_colored_polygon(PackedVector2Array([b + Vector2(-s * 0.3, -s * 0.12), b + Vector2(-s * 0.62, s * 0.02), b + Vector2(-s * 0.52, s * 0.22), b + Vector2(-s * 0.22, s * 0.16)]), col.lightened(0.1))
			ci.draw_colored_polygon(PackedVector2Array([b + Vector2(-s * 0.36, -s * 0.12), b + Vector2(-s * 0.3, -s * 0.32), b + Vector2(-s * 0.24, -s * 0.1)]), col2)
			ci.draw_circle(b + Vector2(-s * 0.42, s * 0.0), s * 0.04, eye)
			for i in 3:
				ci.draw_colored_polygon(PackedVector2Array([b + Vector2(-s * 0.58 + i * s * 0.08, s * 0.14), b + Vector2(-s * 0.54 + i * s * 0.08, s * 0.14), b + Vector2(-s * 0.56 + i * s * 0.08, s * 0.22)]), Color.WHITE)
		"imp":
			ci.draw_colored_polygon(ngon(b + Vector2(0, s * 0.2), s * 0.26, 12), col)
			ci.draw_colored_polygon(PackedVector2Array([b + Vector2(-s * 0.2, -s * 0.0), b + Vector2(-s * 0.42, -s * 0.32), b + Vector2(-s * 0.1, -s * 0.08)]), col2)
			ci.draw_colored_polygon(PackedVector2Array([b + Vector2(s * 0.2, -s * 0.0), b + Vector2(s * 0.42, -s * 0.32), b + Vector2(s * 0.1, -s * 0.08)]), col2)
			ci.draw_circle(b + Vector2(-s * 0.09, s * 0.12), s * 0.05, eye)
			ci.draw_circle(b + Vector2(s * 0.09, s * 0.12), s * 0.05, eye)
			ci.draw_arc(b + Vector2(0, s * 0.26), s * 0.1, 0.3, PI - 0.3, 10, INK, 3)
		"brute":
			ci.draw_colored_polygon(PackedVector2Array([b + Vector2(-s * 0.46, s * 0.5), b + Vector2(-s * 0.5, -s * 0.2), b + Vector2(-s * 0.2, -s * 0.38), b + Vector2(s * 0.2, -s * 0.38), b + Vector2(s * 0.5, -s * 0.2), b + Vector2(s * 0.46, s * 0.5)]), col)
			ci.draw_circle(b + Vector2(-s * 0.46, s * 0.26), s * 0.14, col2)
			ci.draw_circle(b + Vector2(s * 0.46, s * 0.26), s * 0.14, col2)
			ci.draw_rect(Rect2(b + Vector2(-s * 0.2, -s * 0.24), Vector2(s * 0.4, s * 0.08)), col2)
			ci.draw_circle(b + Vector2(-s * 0.1, -s * 0.2), s * 0.04, eye)
			ci.draw_circle(b + Vector2(s * 0.1, -s * 0.2), s * 0.04, eye)
			for i in 5:
				ci.draw_circle(b + Vector2(-s * 0.3 + i * s * 0.15, -s * 0.36), s * 0.05, Color("7ab84a"))
		"wisp":
			glow_circle(ci, b, s * 0.5, col)
			var pts := PackedVector2Array()
			for i in 14:
				var a := TAU * i / 14
				var rr := s * (0.28 + 0.06 * sin(t * 5 + i))
				pts.append(b + Vector2(cos(a) * rr, sin(a) * rr * 1.2 - (s * 0.12 if sin(a) < 0 else 0.0)))
			ci.draw_colored_polygon(pts, col)
			ci.draw_circle(b, s * 0.14, Color.WHITE)
			ci.draw_circle(b + Vector2(-s * 0.06, -s * 0.02), s * 0.03, INK)
			ci.draw_circle(b + Vector2(s * 0.06, -s * 0.02), s * 0.03, INK)
		"tree":
			ci.draw_colored_polygon(PackedVector2Array([b + Vector2(-s * 0.2, s * 0.5), b + Vector2(-s * 0.12, -s * 0.1), b + Vector2(s * 0.12, -s * 0.1), b + Vector2(s * 0.2, s * 0.5)]), col)
			for i in 5:
				var a := -PI + PI * i / 4.0
				ci.draw_line(b + Vector2(0, -s * 0.1), b + Vector2(cos(a) * s * 0.5, -s * 0.2 + sin(a) * s * 0.4 + sin(t * 2 + i) * s * 0.03), col, s * 0.06)
			for i in 7:
				var a := -PI + PI * i / 6.0
				ci.draw_circle(b + Vector2(cos(a) * s * 0.4, -s * 0.3 + sin(a) * s * 0.3), s * 0.16, Color("3a6a2a").lerp(Color.WHITE, flash))
			ci.draw_circle(b + Vector2(-s * 0.06, s * 0.12), s * 0.04, Color("ff9a3a"))
			ci.draw_circle(b + Vector2(s * 0.06, s * 0.12), s * 0.04, Color("ff9a3a"))
			for i in 4:
				ci.draw_line(b + Vector2(-s * 0.1 + i * s * 0.07, s * 0.48), b + Vector2(-s * 0.4 + i * s * 0.25, s * 0.56), col2, s * 0.04)
		"crystal":
			for i in 3:
				var x := (i - 1) * s * 0.22
				var hh := s * (0.5 if i == 1 else 0.34)
				ci.draw_colored_polygon(PackedVector2Array([b + Vector2(x, s * 0.45 - hh * 1.6), b + Vector2(x + s * 0.12, s * 0.45 - hh), b + Vector2(x + s * 0.1, s * 0.48), b + Vector2(x - s * 0.1, s * 0.48), b + Vector2(x - s * 0.12, s * 0.45 - hh)]), col if i == 1 else col.darkened(0.2))
			ci.draw_circle(b + Vector2(-s * 0.04, -s * 0.05), s * 0.03, INK)
			ci.draw_circle(b + Vector2(s * 0.04, -s * 0.05), s * 0.03, INK)
		"cultist":
			ci.draw_colored_polygon(PackedVector2Array([b + Vector2(-s * 0.34, s * 0.5), b + Vector2(-s * 0.16, -s * 0.2), b + Vector2(0, -s * 0.42), b + Vector2(s * 0.16, -s * 0.2), b + Vector2(s * 0.34, s * 0.5)]), col)
			ci.draw_circle(b + Vector2(0, -s * 0.14), s * 0.12, INK)
			ci.draw_circle(b + Vector2(-s * 0.04, -s * 0.15), s * 0.025, eye)
			ci.draw_circle(b + Vector2(s * 0.04, -s * 0.15), s * 0.025, eye)
			ci.draw_line(b + Vector2(-s * 0.2, s * 0.3), b + Vector2(s * 0.2, s * 0.3), col2, s * 0.05)
			glow_circle(ci, b + Vector2(s * 0.3, s * 0.0), s * 0.1, col.lightened(0.4))
		"serpent":
			var pts := PackedVector2Array()
			for i in 26:
				var k := i / 25.0
				pts.append(b + Vector2(-s * 0.46 + k * s * 0.7, s * 0.4 - k * s * 0.6 + sin(k * 9 + t * 3) * s * 0.08))
			ci.draw_polyline(pts, col, s * 0.18, true)
			ci.draw_polyline(pts, col2, s * 0.05, true)
			var hd := pts[pts.size() - 1]
			ci.draw_colored_polygon(ngon(hd, s * 0.16, 10, 0, 1.3), col)
			ci.draw_circle(hd + Vector2(s * 0.05, -s * 0.04), s * 0.035, eye)
			ci.draw_line(hd + Vector2(s * 0.18, s * 0.02), hd + Vector2(s * 0.3, s * 0.06), Color("ff5a6a"), 3)
		"golem":
			ci.draw_colored_polygon(ngon(b + Vector2(0, s * 0.1), s * 0.4, 6, PI / 6), col.darkened(0.15))
			ci.draw_colored_polygon(ngon(b + Vector2(0, s * 0.1), s * 0.26, 6, PI / 6), col)
			ci.draw_colored_polygon(ngon(b + Vector2(0, -s * 0.36), s * 0.15, 4, PI / 4), col.lightened(0.2))
			ci.draw_colored_polygon(ngon(b + Vector2(-s * 0.5, s * 0.12), s * 0.14, 4, t * 0.5), col)
			ci.draw_colored_polygon(ngon(b + Vector2(s * 0.5, s * 0.12), s * 0.14, 4, -t * 0.5), col)
			glow_circle(ci, b + Vector2(0, s * 0.1), s * 0.12, Color("6be0ff"))
			ci.draw_circle(b + Vector2(0, -s * 0.36), s * 0.04, INK)
		"clock":
			ci.draw_circle(b + Vector2(0, s * 0.05), s * 0.4, col2)
			ci.draw_circle(b + Vector2(0, s * 0.05), s * 0.34, col)
			for i in 12:
				var a := TAU * i / 12
				ci.draw_line(b + Vector2(0, s * 0.05) + Vector2(cos(a), sin(a)) * s * 0.28, b + Vector2(0, s * 0.05) + Vector2(cos(a), sin(a)) * s * 0.33, INK, 2)
			ci.draw_line(b + Vector2(0, s * 0.05), b + Vector2(0, s * 0.05) + Vector2(cos(t), sin(t)) * s * 0.24, INK, 4)
			ci.draw_line(b + Vector2(0, s * 0.05), b + Vector2(0, s * 0.05) + Vector2(cos(t / 12), sin(t / 12)) * s * 0.16, INK, 5)
			ci.draw_circle(b + Vector2(0, s * 0.05), s * 0.04, Color("ff5a3a"))
		"lantern":
			ci.draw_line(b + Vector2(0, -s * 0.5), b + Vector2(0, -s * 0.3), col2, 4)
			ci.draw_rect(Rect2(b + Vector2(-s * 0.2, -s * 0.32), Vector2(s * 0.4, s * 0.08)), col2)
			glow_circle(ci, b + Vector2(0, s * 0.05), s * 0.42, col)
			ci.draw_colored_polygon(ngon(b + Vector2(0, s * 0.05), s * 0.26, 6, 0, 0.8), col)
			motif(ci, "flame", b + Vector2(0, s * 0.05), s * 0.3, Color("fff0a0"), t)
			ci.draw_rect(Rect2(b + Vector2(-s * 0.2, s * 0.32), Vector2(s * 0.4, s * 0.08)), col2)
		"knight":
			ci.draw_colored_polygon(PackedVector2Array([b + Vector2(-s * 0.3, s * 0.5), b + Vector2(-s * 0.36, -s * 0.1), b + Vector2(s * 0.36, -s * 0.1), b + Vector2(s * 0.3, s * 0.5)]), col)
			ci.draw_circle(b + Vector2(0, -s * 0.26), s * 0.18, col.lightened(0.15))
			ci.draw_rect(Rect2(b + Vector2(-s * 0.12, -s * 0.29), Vector2(s * 0.24, s * 0.05)), Color("b49cff"))
			ci.draw_colored_polygon(PackedVector2Array([b + Vector2(0, -s * 0.44), b + Vector2(s * 0.1, -s * 0.62), b + Vector2(s * 0.04, -s * 0.42)]), Color("b49cff"))
			ci.draw_line(b + Vector2(s * 0.42, s * 0.4), b + Vector2(s * 0.54, -s * 0.5), Color("d8d0ff"), s * 0.06)
			ci.draw_arc(b + Vector2(0, s * 0.15), s * 0.18, 0, TAU, 20, Color("b49cff", 0.6), 3)
		"void":
			glow_circle(ci, b, s * 0.55, col)
			ci.draw_circle(b, s * 0.3, INK)
			for i in 8:
				var a := TAU * i / 8 + t * 0.5
				var pts := PackedVector2Array()
				for k in 10:
					var rr := s * (0.3 + k * 0.025)
					pts.append(b + Vector2(cos(a + k * 0.12), sin(a + k * 0.12)) * rr)
				ci.draw_polyline(pts, col, 3, true)
			ci.draw_circle(b, s * 0.12, Color.WHITE)
			ci.draw_circle(b + Vector2(sin(t) * s * 0.04, 0), s * 0.06, col2)
		_:
			ci.draw_circle(b, s * 0.3, col)


# ------------------------------------------------------------ small icons

static func intent_icon(ci: CanvasItem, kind: String, c: Vector2, s: float, t: float) -> void:
	match kind:
		"atk":
			motif(ci, "blade", c, s, Color("ff5a4a"), t)
		"def":
			motif(ci, "shield", c, s * 0.9, Color("6ab0ff"), t)
		"buff":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s * 0.45), c + Vector2(s * 0.34, 0), c + Vector2(s * 0.12, 0), c + Vector2(s * 0.12, s * 0.4), c + Vector2(-s * 0.12, s * 0.4), c + Vector2(-s * 0.12, 0), c + Vector2(-s * 0.34, 0)]), Color("ffcf4a"))
		"debuff":
			motif(ci, "skull", c, s * 0.9, Color("c08cff"), t)
		"summon":
			motif(ci, "spiral", c, s * 0.9, Color("8cffd0"), t)


static func status_icon(ci: CanvasItem, st: String, c: Vector2, s: float, t: float) -> void:
	var col: Color = C.STATUS[st]["col"] if C.STATUS.has(st) else Color("d0c0ff")
	ci.draw_circle(c, s * 0.5, Color(0.06, 0.04, 0.1, 0.85))
	var m: String = {"str": "fist", "agi": "wave", "vuln": "burst", "sapped": "moon", "poison": "drop", "regen": "heart", "spikes": "fang", "echo": "rune"}.get(st, "star")
	motif(ci, m, c, s * 0.8, col, t)


static func relic(ci: CanvasItem, id: String, c: Vector2, s: float, t: float) -> void:
	var r: Dictionary = D.RELICS[id]
	ci.draw_circle(c, s * 0.5, Color(0.1, 0.07, 0.16))
	ci.draw_arc(c, s * 0.5, 0, TAU, 24, Color(r["col"], 0.8), 2)
	motif(ci, r["art"], c, s * 0.72, r["col"], t)


static func node_icon(ci: CanvasItem, kind: String, c: Vector2, s: float, t: float, col: Color) -> void:
	match kind:
		"fight":
			motif(ci, "blade", c, s, col, t)
		"elite":
			motif(ci, "skull", c, s, col, t)
		"rest":
			motif(ci, "flame", c, s, col, t)
		"shop":
			motif(ci, "orb", c, s * 0.9, col, t)
		"event":
			text_c(ci, c, "?", int(s * 0.8), col, 3)
		"treasure":
			ci.draw_rect(Rect2(c + Vector2(-s * 0.36, -s * 0.12), Vector2(s * 0.72, s * 0.42)), col.darkened(0.3))
			ci.draw_rect(Rect2(c + Vector2(-s * 0.38, -s * 0.3), Vector2(s * 0.76, s * 0.2)), col)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.06, -s * 0.16), Vector2(s * 0.12, s * 0.16)), Color("ffe27a"))
		"boss":
			motif(ci, "crown", c, s, col, t)


static func energy_orb(ci: CanvasItem, c: Vector2, r: float, cur: int, mx: int, col: Color, t: float) -> void:
	glow_circle(ci, c, r * 1.4, col)
	ci.draw_circle(c, r, col.darkened(0.5))
	ci.draw_circle(c, r * 0.84, col)
	ci.draw_arc(c, r * 1.05, t, t + PI, 24, col.lightened(0.5), 3)
	text_c(ci, c, "%d/%d" % [cur, mx], int(r * 0.62), INK)


static func coin(ci: CanvasItem, c: Vector2, r: float) -> void:
	ci.draw_circle(c, r, Color("b8860b"))
	ci.draw_circle(c, r * 0.78, Color("ffd54a"))
	ci.draw_rect(Rect2(c + Vector2(-r * 0.15, -r * 0.45), Vector2(r * 0.3, r * 0.9)), Color("b8860b"))


static func heart(ci: CanvasItem, c: Vector2, r: float) -> void:
	motif(ci, "heart", c, r * 2.0, Color("ff4a6a"))
