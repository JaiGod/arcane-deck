extends RefCounted
## Arcane Deck - every non-combat screen and overlay. Draws on `m` (main).

const C := preload("res://scripts/cards.gd")
const D := preload("res://scripts/data.gd")
const A := preload("res://scripts/art.gd")
const ROMAN := ["I", "II", "III"]
const NODE_COL := {"fight": Color("ff8a6a"), "elite": Color("ff4a6a"), "rest": Color("ffb84a"), "shop": Color("ffd54a"), "event": Color("8cd0ff"), "treasure": Color("ffe27a"), "boss": Color("d8a8ff")}

var m


func cw() -> float:
	return m.W


func ch() -> float:
	return m.H


func background() -> void:
	var W: float = m.W
	var H: float = m.H
	var top := Color("0a0814")
	var bot := Color("1c1238")
	if m.run != null and m.screen not in ["title", "heroes", "history", "help", "end"]:
		top = D.ACTS[m.run.act]["sky"]
		bot = D.ACTS[m.run.act]["sky2"]
	m.draw_polygon(PackedVector2Array([Vector2(-20, -20), Vector2(W + 20, -20), Vector2(W + 20, H + 20), Vector2(-20, H + 20)]), PackedColorArray([top, top, bot, bot]))
	for s in m.stars:
		var tw: float = 0.5 + 0.5 * sin(m.t * 2.0 * s.z + s.x * 40.0)
		var p := Vector2(fmod(s.x * W + m.t * 6.0 * s.z, W), s.y * H)
		m.draw_circle(p, 1.0 + s.z, Color(1, 1, 1, 0.15 + 0.35 * tw * s.z))


func heading(y: float, s: String, size := 40, col := Color("ffe9b8")) -> void:
	A.text_c(m, Vector2(m.W / 2, y), s, size, col, 5)


# ------------------------------------------------------------ title

func title() -> void:
	var W: float = m.W
	var H: float = m.H
	var t: float = m.t
	for i in m.title_cards.size():
		var a: float = t * 0.15 + i * TAU / m.title_cards.size()
		var p := Vector2(W / 2 + cos(a) * W * 0.36, H * 0.42 + sin(a) * H * 0.18)
		m.draw_set_transform(p + m.shake_off, sin(a) * 0.2, Vector2(0.8, 0.8))
		A.card(m, Vector2(-75, -105), m.title_cards[i], false, t)
		m.draw_set_transform(m.shake_off)
	m.draw_rect(Rect2(0, 0, W, H), Color(0.04, 0.03, 0.08, 0.55))
	var ty := H * (0.16 if not m.portrait else 0.13)
	var fs := 84 if not m.portrait else 64
	A.glow_circle(m, Vector2(W / 2, ty), 220, Color("7a5cff"), 6)
	A.text_c(m, Vector2(W / 2 + 3, ty + 4), "ARCANE DECK", fs, Color("2a1050"), 0)
	A.text_c(m, Vector2(W / 2, ty), "ARCANE DECK", fs, Color("ffe9b8"), 8)
	A.text_c(m, Vector2(W / 2, ty + fs * 0.75), "A deck-building roguelike of spells, relics and three cursed acts", 19 if not m.portrait else 16, Color("cbb8ff"), 2)
	var bw := 320.0
	var y := H * (0.36 if not m.portrait else 0.3)
	var x := W / 2 - bw / 2
	if m.has_save():
		m.button(Rect2(x, y, bw, 58), "Continue Run", m.continue_run, Color("5ad18a"), true, 24)
		y += 70
	m.button(Rect2(x, y, bw, 58), "New Run", func(): m.go("heroes"); m.sfx.play("click"), Color("ffb84a"), true, 24)
	y += 70
	m.button(Rect2(x, y, bw, 50), "How to Play", func(): m.help_page = 0; m.go("help"), Color("7a5cff"))
	y += 62
	m.button(Rect2(x, y, bw, 50), "Run History", func(): m.go("history"), Color("7a5cff"))
	y += 62
	m.button(Rect2(x, y, bw / 2 - 6, 46), "Sound: " + ("On" if m.meta["sound"] else "Off"), m.toggle_sound, Color("6ab0ff"), true, 18)
	m.button(Rect2(x + bw / 2 + 6, y, bw / 2 - 6, 46), "Music: " + ("On" if m.meta["music"] else "Off"), m.toggle_music, Color("6ab0ff"), true, 18)
	y += 70
	A.text_c(m, Vector2(W / 2, y), "Best score %d   -   Runs %d   -   Wins %d   -   Cards unlocked %d/4" % [m.meta["best"], m.meta["runs"], m.meta["wins"], m.meta["unlock"]], 17, Color("ffd54a"), 2)
	A.text_c(m, Vector2(W / 2, H - 24), "Made by Jaineil Rana (JaKing)  -  part of JaiGod", 15, Color(0.75, 0.7, 0.85), 2)


# ------------------------------------------------------------ heroes

func heroes() -> void:
	var W: float = m.W
	var H: float = m.H
	heading(52, "Choose your hero", 42)
	for h in 3:
		var r: Rect2
		if m.portrait:
			var ph := (H - 200) / 3.0
			r = Rect2(20, 96 + h * ph, W - 40, ph - 16)
		else:
			var pw := minf(380.0, (W - 80) / 3.0)
			r = Rect2(W / 2 - pw * 1.5 - 20 + h * (pw + 20), 100, pw, minf(H - 200, 500))
		hero_panel(r, h)
	m.button(Rect2(20, H - 74, 150, 54), "Back", func(): m.go("title"), Color("9a8cb8"))


func hero_panel(r: Rect2, h: int) -> void:
	var hd: Dictionary = C.HEROES[h]
	var col: Color = hd["col"]
	var hot := r.has_point(m.hover)
	A.panel(m, r, Color(col.darkened(0.82), 0.95), col if hot else col.darkened(0.3), 16, 3)
	var start := func(): m.new_run(h)
	if m.portrait:
		var ac := Vector2(r.position.x + 100, r.position.y + r.size.y * 0.55)
		A.glow_circle(m, ac, 90, col)
		A.hero(m, h, ac, minf(170.0, r.size.y * 0.75), m.t)
		var tx := r.position.x + 200
		var tw := r.size.x - 215
		A.text(m, Vector2(tx, r.position.y + 38), hd["name"], 30, col, HORIZONTAL_ALIGNMENT_LEFT, -1, 3)
		A.text(m, Vector2(tx, r.position.y + 62), hd["title"] + "   -   %d HP" % hd["hp"], 17, Color(0.85, 0.8, 0.9))
		A.para(m, Vector2(tx, r.position.y + 70), hd["blurb"], 16, Color("f4ead8"), tw, HORIZONTAL_ALIGNMENT_LEFT, 4)
		A.relic(m, hd["relic"], Vector2(tx + 16, r.end.y - 84), 30, m.t)
		A.text(m, Vector2(tx + 38, r.end.y - 78), D.RELICS[hd["relic"]]["n"], 16, Color("ffd54a"))
		m.tip(Rect2(tx, r.end.y - 100, 200, 34), D.RELICS[hd["relic"]]["d"])
		m.button(Rect2(r.end.x - 170, r.end.y - 58, 154, 46), "Choose", start, col, true, 20)
		return
	var ac := Vector2(r.get_center().x, r.position.y + 150)
	A.glow_circle(m, ac, 120, col)
	A.hero(m, h, ac, 210, m.t)
	var y := r.position.y + 290
	A.text_c(m, Vector2(r.get_center().x, y), hd["name"], 34, col, 3)
	A.text_c(m, Vector2(r.get_center().x, y + 32), hd["title"], 18, Color(0.85, 0.8, 0.9))
	A.text_c(m, Vector2(r.get_center().x, y + 58), "%d HP" % hd["hp"], 18, Color("ff8a9a"))
	A.para(m, Vector2(r.position.x + 20, y + 68), hd["blurb"], 16, Color("f4ead8"), r.size.x - 40, HORIZONTAL_ALIGNMENT_CENTER, 4)
	var ry := r.end.y - 110
	A.relic(m, hd["relic"], Vector2(r.position.x + 36, ry), 34, m.t)
	A.text(m, Vector2(r.position.x + 62, ry - 2), D.RELICS[hd["relic"]]["n"], 17, Color("ffd54a"))
	A.para(m, Vector2(r.position.x + 62, ry), D.RELICS[hd["relic"]]["d"], 13, Color(0.85, 0.8, 0.9), r.size.x - 80, HORIZONTAL_ALIGNMENT_LEFT, 2)
	m.button(Rect2(r.position.x + 30, r.end.y - 64, r.size.x - 60, 48), "Choose " + hd["name"], start, col, true, 21)


# ------------------------------------------------------------ map

func node_pos(row: int, col: int, top: float) -> Vector2:
	var W: float = m.W
	var dx := minf(130.0, (W - 90) / 6.0)
	var dy := 96.0 if not m.portrait else 104.0
	var bottom: float = m.H - 70 + m.map_scroll
	if row >= 10:
		return Vector2(W / 2, bottom - 10 * dy - 30)
	var h := hash(Vector3i(m.run.seed_v % 99991, row, col))
	var jx := ((h % 100) / 100.0 - 0.5) * dx * 0.4
	var jy := (((h / 100) % 100) / 100.0 - 0.5) * dy * 0.3
	return Vector2(W / 2 + (col - 3) * dx + jx, bottom - row * dy + jy)


func map_screen() -> void:
	var run = m.run
	var W: float = m.W
	var H: float = m.H
	var dy := 96.0 if not m.portrait else 104.0
	var hh: float = 64.0 if not m.portrait else 108.0
	var total := 10 * dy + 120
	var smin := 0.0
	var smax := maxf(0.0, total - (H - hh - 40))
	if m.map_scroll < 0:
		var row := maxi(0, run.pos.x)
		m.map_scroll = clampf(row * dy - (H - hh) * 0.35, smin, smax)
	m.map_scroll = clampf(m.map_scroll, smin, smax)
	var top := hh
	var acc: Color = D.ACTS[run.act]["acc"]
	A.panel(m, Rect2(W / 2 - minf(500.0, W / 2 - 10), hh + 8, minf(1000.0, W - 20), H - hh - 16), Color(0, 0, 0, 0.25), Color(acc, 0.25), 18, 2)
	var av: Array = run.available()
	# edges
	for r in 10:
		for c in 7:
			var n = run.map[r][c]
			if n == null:
				continue
			var a := node_pos(r, c, top)
			var nexts: Array = n["next"] if r < 9 else [3]
			for nc in nexts:
				var b := node_pos(r + 1, nc, top) if r < 9 else node_pos(10, 3, top)
				var visited: bool = run.pos.x == r and run.pos.y == c
				var col := Color(acc, 0.55) if visited else Color(0.85, 0.8, 0.95, 0.22)
				_dashed(a, b, col, 3.0 if visited else 2.0)
	# nodes
	for r in 11:
		for c in 7:
			if r == 10 and c != 3:
				continue
			if r < 10 and run.map[r][c] == null:
				continue
			var v := Vector2i(r, c)
			var kind: String = run.node_type(v)
			var p := node_pos(r, c, top)
			if p.y < hh - 30 or p.y > H + 40:
				continue
			var is_av := av.has(v)
			var is_cur: bool = run.pos == v
			var done: bool = r < run.pos.x or is_cur
			var rad := 26.0 if r < 10 else 52.0
			var col: Color = NODE_COL[kind]
			if done and not is_cur:
				col = col.darkened(0.55)
			if is_av:
				var pul := 0.5 + 0.5 * sin(m.t * 5.0)
				A.glow_circle(m, p, rad * (1.6 + pul * 0.3), col)
				m.draw_arc(p, rad + 6 + pul * 4, 0, TAU, 32, Color(col, 0.9), 3)
			m.draw_circle(p, rad, Color(0.08, 0.05, 0.14, 0.95))
			m.draw_arc(p, rad, 0, TAU, 32, col if (is_av or is_cur) else Color(col, 0.5), 2.5)
			A.node_icon(m, kind, p, rad * 1.25, m.t, col if (is_av or is_cur or not done) else col.darkened(0.2))
			if is_cur:
				m.draw_arc(p, rad + 8, m.t * 2, m.t * 2 + PI * 1.4, 24, Color.WHITE, 3)
			var rr := Rect2(p - Vector2(rad + 8, rad + 8), Vector2(rad * 2 + 16, rad * 2 + 16))
			var desc: String = D.NODE_NAMES[kind]
			if kind == "boss":
				desc = "Boss: " + str(D.ENEMIES[D.ENCOUNTERS[run.act]["boss"][0]]["n"])
			m.tip(rr, desc + ("\nTap to travel here." if is_av else ""))
			if is_av:
				m.hot(rr, m.enter_node.bind(v))
	m.hud()
	# legend
	if not m.portrait:
		var ly := hh + 40
		for k in ["fight", "elite", "event", "rest", "shop", "treasure"]:
			A.node_icon(m, k, Vector2(42, ly), 28, m.t, NODE_COL[k])
			A.text(m, Vector2(64, ly + 6), D.NODE_NAMES[k], 16, Color(0.85, 0.8, 0.9))
			ly += 40
		A.text(m, Vector2(24, H - 30), "Drag or scroll to look ahead", 14, Color(0.7, 0.65, 0.8))
	else:
		A.text_c(m, Vector2(W / 2, H - 20), "Tap a glowing node to travel. Drag to look ahead.", 15, Color(0.8, 0.75, 0.9), 2)


func _dashed(a: Vector2, b: Vector2, col: Color, w: float) -> void:
	var d := a.distance_to(b)
	var n := int(d / 14)
	for i in n:
		if i % 2 == 0:
			m.draw_line(a.lerp(b, float(i) / n), a.lerp(b, float(i + 1) / n), col, w)


# ------------------------------------------------------------ rewards

func reward_screen() -> void:
	var W: float = m.W
	var H: float = m.H
	var hh: float = m.hud()
	var rw: Dictionary = m.reward
	var y := hh + 60
	heading(y, "Victory!" if rw.get("kind", "") != "card_choice" else "Choose a card", 44, Color("ffe27a"))
	y += 52
	if rw.get("gold", 0) > 0:
		A.coin(m, Vector2(W / 2 - 70, y), 13)
		A.text(m, Vector2(W / 2 - 50, y + 8), "+%d gold" % rw["gold"], 24, Color("ffd54a"), HORIZONTAL_ALIGNMENT_LEFT, -1, 2)
		y += 40
	if rw.get("relic", "") != "":
		var id: String = rw["relic"]
		A.relic(m, id, Vector2(W / 2 - 150, y), 36, m.t)
		A.text(m, Vector2(W / 2 - 124, y + 2), "Relic: " + D.RELICS[id]["n"], 20, Color("ffcf6a"), HORIZONTAL_ALIGNMENT_LEFT, -1, 2)
		A.text(m, Vector2(W / 2 - 124, y + 24), D.RELICS[id]["d"], 14, Color(0.85, 0.8, 0.9))
		y += 52
	var cards: Array = rw.get("cards", [])
	if not cards.is_empty() and not rw.get("taken", false):
		A.text_c(m, Vector2(W / 2, y + 6), "Add a card to your deck", 20, Color("f4ead8"), 2)
		y += 30
		var sz := Vector2(190, 266) if not m.portrait else Vector2(180, 252)
		var gap := 26.0 if not m.portrait else 12.0
		var x0 := W / 2 - (cards.size() * sz.x + (cards.size() - 1) * gap) / 2
		for i in cards.size():
			var p := Vector2(x0 + i * (sz.x + gap), y)
			var r := Rect2(p, sz)
			var h := r.has_point(m.hover)
			A.card(m, p - Vector2(0, 8 if h else 0), cards[i], false, m.t, sz, true, 0, false, h)
			m.hot(r, take_card.bind(i))
		y += sz.y + 26
	m.button(Rect2(W / 2 - 120, minf(y, H - 76), 240, 54), "Skip card" if not rw.get("taken", false) and not cards.is_empty() else "Continue", m.reward_done, Color("9a8cb8"))


func take_card(i: int) -> void:
	var cards: Array = m.reward.get("cards", [])
	if i >= cards.size():
		return
	m.run.add_card(cards[i])
	m.sfx.play("card")
	m.show_toast(C.CARDS[cards[i]]["n"] + " added to your deck")
	m.burst(Vector2(m.W / 2, m.H / 2), Color("ffe27a"), 30)
	m.reward_done()


func boss_relic() -> void:
	var W: float = m.W
	var hh: float = m.hud()
	heading(hh + 60, "The boss falls!", 44, Color("ffe27a"))
	A.text_c(m, Vector2(W / 2, hh + 110), "Claim one boss relic to carry into Act %s" % ROMAN[mini(2, m.run.act + 1)], 20, Color("f4ead8"), 2)
	var opts: Array = m.reward.get("boss_relics", [])
	var bw := minf(300.0, (W - 60) / 3.0) if not m.portrait else W - 60
	for i in opts.size():
		var r := Rect2(W / 2 - bw * 1.5 - 15 + i * (bw + 15), hh + 150, bw, 230) if not m.portrait else Rect2(30, hh + 150 + i * 190, bw, 175)
		var id: String = opts[i]
		var hot := r.has_point(m.hover)
		A.panel(m, r, Color(0.1, 0.06, 0.18, 0.95), Color("ffcf6a") if hot else Color("8a6ab8"), 14, 3)
		A.relic(m, id, Vector2(r.get_center().x, r.position.y + 60), 70, m.t)
		A.text_c(m, Vector2(r.get_center().x, r.position.y + 122), D.RELICS[id]["n"], 22, Color("ffcf6a"), 2)
		A.para(m, Vector2(r.position.x + 14, r.position.y + 132), D.RELICS[id]["d"], 15, Color("f4ead8"), r.size.x - 28, HORIZONTAL_ALIGNMENT_CENTER, 3)
		m.hot(r, pick_boss_relic.bind(i))


func pick_boss_relic(i: int) -> void:
	var opts: Array = m.reward.get("boss_relics", [])
	if i < opts.size():
		m.run.add_relic(opts[i])
		m.sfx.play("relic")
	m.next_act()


# ------------------------------------------------------------ shop

func shop() -> void:
	var run = m.run
	var W: float = m.W
	var H: float = m.H
	var hh: float = m.hud()
	heading(hh + 44, "The Merchant", 38, Color("ffd54a"))
	A.text_c(m, Vector2(W / 2, hh + 80), m.shop_msg if m.shop_msg != "" else "\"Cards, trinkets, and a clean slate. All for coin.\"", 17, Color(0.85, 0.8, 0.9), 2)
	var cards: Array = run.shop["cards"]
	var sz := Vector2(150, 210)
	var per_row := cards.size() if not m.portrait else 3
	var gap := 18.0 if not m.portrait else 14.0
	var y := hh + 104
	for i in cards.size():
		var row := i / per_row
		var col := i % per_row
		var n_in := mini(per_row, cards.size() - row * per_row)
		var x0 := W / 2 - (n_in * sz.x + (n_in - 1) * gap) / 2
		var p := Vector2(x0 + col * (sz.x + gap), y + row * (sz.y + 46))
		var it: Dictionary = cards[i]
		if it["sold"]:
			A.panel(m, Rect2(p, sz), Color(0, 0, 0, 0.25), Color(0.4, 0.35, 0.5, 0.5), 12, 2)
			A.text_c(m, p + sz / 2, "Sold", 22, Color(0.6, 0.55, 0.7))
			continue
		var afford: bool = run.gold >= it["price"]
		var r := Rect2(p, sz)
		var h := r.has_point(m.hover)
		A.card(m, p - Vector2(0, 6 if h else 0), it["id"], false, m.t, sz, afford, 0, false, h and afford)
		A.coin(m, p + Vector2(sz.x / 2 - 26, sz.y + 18), 10)
		A.text(m, p + Vector2(sz.x / 2 - 12, sz.y + 25), str(it["price"]), 20, Color("ffd54a") if afford else Color("ff6a6a"), HORIZONTAL_ALIGNMENT_LEFT, -1, 2)
		m.hot(r, _buy_card.bind(i))
	var rows := int(ceil(cards.size() / float(per_row)))
	y += rows * (sz.y + 46) + 6
	# relics + removal
	var rel: Array = run.shop["relics"]
	var bw := 280.0 if not m.portrait else (W - 40) / 2.0 - 6
	var items := rel.size() + 1
	var x0 := W / 2 - (items * bw + (items - 1) * 12) / 2 if not m.portrait else 20.0
	for i in items:
		var r := Rect2(x0 + i * (bw + 12), y, bw, 74) if not m.portrait else Rect2(20 + (i % 2) * (bw + 12), y + (i / 2) * 86, bw, 74)
		if i < rel.size():
			var it: Dictionary = rel[i]
			var id: String = it["id"]
			var afford: bool = run.gold >= it["price"] and not it["sold"]
			A.panel(m, r, Color(0.1, 0.06, 0.18, 0.95), Color("ffcf6a") if r.has_point(m.hover) and afford else Color("6a5a8a"), 12, 2)
			if it["sold"]:
				A.text_c(m, r.get_center(), "Sold", 20, Color(0.6, 0.55, 0.7))
				continue
			A.relic(m, id, r.position + Vector2(36, 37), 46, m.t)
			A.text(m, r.position + Vector2(68, 30), D.RELICS[id]["n"], 17, Color("ffcf6a"))
			A.coin(m, r.position + Vector2(76, 52), 9)
			A.text(m, r.position + Vector2(90, 59), str(it["price"]), 18, Color("ffd54a") if afford else Color("ff6a6a"))
			m.tip(r, D.RELICS[id]["n"] + "\n" + D.RELICS[id]["d"])
			m.hot(r, _buy_relic.bind(i))
		else:
			var price: int = run.removal_price()
			var ok: bool = run.gold >= price and not run.shop["removed"] and run.deck.size() > 5
			A.panel(m, r, Color(0.1, 0.06, 0.18, 0.95), Color("ff8a6a") if r.has_point(m.hover) and ok else Color("6a5a8a"), 12, 2)
			A.motif(m, "skull", r.position + Vector2(36, 37), 40, Color("ff8a6a"), m.t)
			A.text(m, r.position + Vector2(68, 30), "Remove a card" if not run.shop["removed"] else "Removal used", 17, Color("ff9a8a"))
			A.coin(m, r.position + Vector2(76, 52), 9)
			A.text(m, r.position + Vector2(90, 59), str(price), 18, Color("ffd54a") if ok else Color("ff6a6a"))
			m.tip(r, "Thin your deck: remove one card for good. Fewer weak cards means you draw your best ones more often.")
			if ok:
				m.hot(r, func(): m.open_cards("Choose a card to remove", m.deck_list(), "remove", _remove_card))
	m.button(Rect2(W / 2 - 110, H - 72, 220, 54), "Leave", func(): m.go("map"), Color("9a8cb8"))


func _buy_card(i: int) -> void:
	var it: Dictionary = m.run.shop["cards"][i]
	if m.run.buy_card(i):
		m.sfx.play("gold")
		m.shop_msg = "\"%s - a fine choice.\"" % C.CARDS[it["id"]]["n"]
		m.burst(m.hover, Color("ffd54a"), 18)
	else:
		m.sfx.play("deny")
		m.shop_msg = "\"You can't afford that, friend.\""


func _buy_relic(i: int) -> void:
	if m.run.buy_relic(i):
		m.sfx.play("relic")
		m.shop_msg = "\"May it serve you well.\""
		m.burst(m.hover, Color("ffcf6a"), 22)
	else:
		m.sfx.play("deny")


func _remove_card(i: int) -> void:
	var nm: String = C.CARDS[m.run.deck[i]["id"]]["n"]
	m.run.gold -= m.run.removal_price()
	m.run.remove_card(i)
	m.run.removal_cost += 25
	m.run.shop["removed"] = true
	m.overlay = ""
	m.shop_msg = "\"%s, gone for good.\"" % nm
	m.sfx.play("die")


# ------------------------------------------------------------ rest

func rest() -> void:
	var run = m.run
	var W: float = m.W
	var H: float = m.H
	var hh: float = m.hud()
	heading(hh + 50, "Campfire", 40, Color("ffb84a"))
	var c := Vector2(W / 2, hh + (190 if not m.portrait else 240))
	A.glow_circle(m, c, 150, Color("ff8a3a"), 7)
	for i in 3:
		m.draw_line(c + Vector2(-60 + i * 20, 50), c + Vector2(60 - i * 20, 30), Color("6a4a2a"), 10)
	A.motif(m, "flame", c, 130, Color("ff9a3a"), m.t)
	A.motif(m, "flame", c + Vector2(0, 14), 70, Color("ffe27a"), m.t * 1.3)
	if m.t * 60.0 - floor(m.t * 60.0) < 0.2:
		m.particles.append({"p": c + Vector2(randf_range(-30, 30), -20), "v": Vector2(randf_range(-20, 20), -120), "life": 1.0, "max": 1.0, "col": Color("ffb84a"), "s": 2.0})
	var amt: int = mini(run.rest_amount(), run.max_hp - run.hp)
	var y := c.y + 130
	var bw := 300.0
	var both: bool = not m.portrait
	var r1 := Rect2(W / 2 - bw - 12, y, bw, 120) if both else Rect2(W / 2 - bw / 2, y, bw, 110)
	var r2 := Rect2(W / 2 + 12, y, bw, 120) if both else Rect2(W / 2 - bw / 2, y + 126, bw, 110)
	_big_choice(r1, "Rest", "Heal %d HP" % run.rest_amount(), Color("ff8a9a"), do_rest)
	var ups: Array = run.upgradable()
	_big_choice(r2, "Smith", "Upgrade a card" if not ups.is_empty() else "Nothing to upgrade", Color("8cff9a"), _smith, not ups.is_empty())
	if amt <= 0:
		A.text_c(m, Vector2(W / 2, r2.end.y + 30), "You are at full health.", 16, Color(0.8, 0.75, 0.9))


func _big_choice(r: Rect2, title: String, sub: String, col: Color, cb: Callable, en := true) -> void:
	var h := r.has_point(m.hover) and en
	A.panel(m, r, Color(col.darkened(0.8), 0.95), col if h else col.darkened(0.4), 16, 3)
	A.text_c(m, r.get_center() - Vector2(0, 18), title, 32, col if en else Color(0.5, 0.5, 0.55), 3)
	A.text_c(m, r.get_center() + Vector2(0, 22), sub, 18, Color("f4ead8") if en else Color(0.5, 0.5, 0.55))
	m.buttons.append({"r": r, "cb": cb, "en": en})


func do_rest() -> void:
	var before: int = m.run.hp
	m.run.hp = mini(m.run.max_hp, m.run.hp + m.run.rest_amount())
	m.sfx.play("heal")
	m.show_toast("Rested: +%d HP" % (m.run.hp - before))
	m.go("map")


func _smith() -> void:
	var list: Array = []
	for i in m.run.upgradable():
		list.append({"id": m.run.deck[i]["id"], "up": true, "i": i})
	m.open_cards("Choose a card to upgrade (preview shows the upgrade)", list, "upgrade", func(i):
		m.run.deck[i]["up"] = true
		m.sfx.play("buff")
		m.show_toast(C.CARDS[m.run.deck[i]["id"]]["n"] + " upgraded!")
		m.go("map"))


# ------------------------------------------------------------ events

func event() -> void:
	var W: float = m.W
	var H: float = m.H
	var hh: float = m.hud()
	var ev: Dictionary = D.EVENTS[m.event_i]
	var pw := minf(760.0, W - 30)
	var r := Rect2(W / 2 - pw / 2, hh + 20, pw, H - hh - 40)
	A.panel(m, r, Color(0.08, 0.05, 0.14, 0.94), Color("8cd0ff"), 18, 3)
	var ac := Vector2(W / 2, r.position.y + 110)
	A.glow_circle(m, ac, 90, Color("8cd0ff"))
	A.motif(m, ev["art"], ac, 130, Color("8cd0ff"), m.t)
	A.text_c(m, Vector2(W / 2, r.position.y + 210), ev["n"], 32, Color("ffe9b8"), 3)
	A.para(m, Vector2(r.position.x + 30, r.position.y + 226), ev["d"], 18, Color("f4ead8"), pw - 60, HORIZONTAL_ALIGNMENT_CENTER, 4)
	var y := r.position.y + 330
	if m.event_result != "":
		A.para(m, Vector2(r.position.x + 30, y - 10), m.event_result, 19, Color("ffd54a"), pw - 60, HORIZONTAL_ALIGNMENT_CENTER, 4)
		m.button(Rect2(W / 2 - 110, minf(y + 90, r.end.y - 70), 220, 52), "Continue", func(): m.go("map"), Color("8cd0ff"))
		return
	var chs: Array = ev["ch"]
	for i in chs.size():
		var chd: Dictionary = chs[i]
		var en: bool = m.run.gold >= int(chd.get("need", 0))
		m.button(Rect2(r.position.x + 30, y + i * 64, pw - 60, 54), chd["t"], choose_event.bind(i), Color("8cd0ff"), en, 18 if not m.portrait else 16)


func choose_event(ci: int) -> void:
	var run = m.run
	var before := {"hp": run.hp, "max": run.max_hp, "gold": run.gold, "deck": run.deck.size(), "rel": run.relics.size(), "ups": 0}
	for cd in run.deck:
		if cd["up"]:
			before["ups"] += 1
	var follow: String = run.event_choose(m.event_i, ci)
	if follow == "nogold":
		m.sfx.play("deny")
		return
	m.sfx.play("click")
	if follow == "fight":
		m.start_battle(run.encounter("elite"), "event_fight")
		return
	if follow == "card_choice":
		m.reward = {"gold": 0, "kind": "card_choice", "cards": run.card_choices("elite"), "relic": ""}
		m.go("reward")
		return
	var out: PackedStringArray = []
	if run.max_hp != before["max"]:
		out.append("Max HP %+d" % (run.max_hp - before["max"]))
	if run.hp != before["hp"]:
		out.append("HP %+d" % (run.hp - before["hp"]))
	if run.gold != before["gold"]:
		out.append("Gold %+d" % (run.gold - before["gold"]))
	if run.relics.size() > before["rel"]:
		out.append("New relic: " + D.RELICS[run.relics[-1]]["n"])
	var ups := 0
	for cd in run.deck:
		if cd["up"]:
			ups += 1
	if ups > before["ups"]:
		out.append("%d card(s) upgraded" % (ups - before["ups"]))
	if run.deck.size() > before["deck"]:
		out.append("Gained " + C.CARDS[run.deck[-1]["id"]]["n"])
	elif run.deck.size() < before["deck"]:
		out.append("A card was removed from your deck")
	m.event_result = "Nothing happens. You move on." if out.is_empty() else "   -   ".join(out)
	if run.relics.size() > before["rel"]:
		m.sfx.play("relic")
	m.save_run()


# ------------------------------------------------------------ treasure

func treasure() -> void:
	var W: float = m.W
	var hh: float = m.hud()
	heading(hh + 60, "Treasure!", 42, Color("ffe27a"))
	var c := Vector2(W / 2, hh + 230)
	A.glow_circle(m, c, 160, Color("ffe27a"), 7)
	var id: String = m.reward.get("relic", "")
	if id == "":
		A.node_icon(m, "treasure", c, 150, m.t, Color("ffd54a"))
		A.text_c(m, Vector2(W / 2, c.y + 120), "The chest is empty.", 20, Color("f4ead8"))
	else:
		A.relic(m, id, c, 140 + sin(m.t * 3) * 6, m.t)
		A.text_c(m, Vector2(W / 2, c.y + 110), D.RELICS[id]["n"], 30, Color("ffcf6a"), 3)
		A.para(m, Vector2(W / 2 - 230, c.y + 124), D.RELICS[id]["d"], 18, Color("f4ead8"), 460, HORIZONTAL_ALIGNMENT_CENTER, 3)
	m.button(Rect2(W / 2 - 110, c.y + 210, 220, 56), "Take it" if id != "" else "Continue", take_treasure, Color("ffd54a"))


func take_treasure() -> void:
	var id: String = m.reward.get("relic", "")
	if id != "":
		m.run.add_relic(id)
		m.sfx.play("relic")
		m.burst(Vector2(m.W / 2, m.H / 2), Color("ffe27a"), 40)
	m.go("map")


# ------------------------------------------------------------ end of run

func end_screen() -> void:
	var run = m.run
	var W: float = m.W
	var H: float = m.H
	var info: Dictionary = m.end_info
	var won: bool = info["won"]
	var col := Color("ffe27a") if won else Color("ff6a7a")
	heading(H * 0.12, "VICTORY!" if won else "DEFEATED", 64, col)
	A.text_c(m, Vector2(W / 2, H * 0.12 + 50), ("The Unwoven is no more. The stars are safe." if won else "Your run ends in %s." % D.ACTS[run.act]["name"]), 19, Color("f4ead8"), 2)
	A.hero(m, run.hero, Vector2(W / 2, H * 0.12 + 170), 170, m.t)
	var y := H * 0.12 + 280
	var rows := [["Hero", C.HEROES[run.hero]["name"]], ["Reached", "Act %s, floor %d" % [ROMAN[run.act], run.floor_n]], ["Enemies defeated", str(run.stats["kills"])],
		["Elites / bosses", "%d / %d" % [run.stats["elites"], run.stats["bosses"]]], ["Cards played", str(run.stats["cards"])], ["Damage dealt", str(run.stats["dmg"])], ["Final deck", "%d cards, %d relics" % [run.deck.size(), run.relics.size()]]]
	for rw in rows:
		A.text(m, Vector2(W / 2 - 200, y), rw[0], 18, Color(0.8, 0.75, 0.9))
		var sw := A.font().get_string_size(rw[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
		A.text(m, Vector2(W / 2 + 200 - sw, y), rw[1], 18, Color("f4ead8"))
		y += 28
	y += 14
	A.text_c(m, Vector2(W / 2, y), "Score %d%s" % [info["score"], "   -   NEW BEST!" if info["best"] else "   (best %d)" % m.meta["best"]], 28, Color("ffd54a"), 3)
	y += 38
	var ul: Array = info["unlocked"]
	if not ul.is_empty():
		A.text_c(m, Vector2(W / 2, y), "New cards unlocked: " + ", ".join(ul), 17, Color("8cff9a"), 2)
		y += 30
	var by := minf(y + 16, H - 76)
	m.button(Rect2(W / 2 - 230, by, 220, 56), "New Run", func(): m.go("heroes"), Color("ffb84a"))
	m.button(Rect2(W / 2 + 10, by, 220, 56), "Title", func(): m.go("title"), Color("9a8cb8"))
	if won and int(m.t * 10) % 3 == 0:
		m.burst(Vector2(randf() * W, randf() * H * 0.5), Color.from_hsv(randf(), 0.6, 1.0), 6, 200)


# ------------------------------------------------------------ history + help

func history() -> void:
	var W: float = m.W
	var H: float = m.H
	heading(56, "Run History", 42)
	var hist: Array = m.meta["history"]
	A.text_c(m, Vector2(W / 2, 100), "Runs %d   -   Wins %d   -   Best score %d   -   Bosses slain %d" % [m.meta["runs"], m.meta["wins"], m.meta["best"], m.meta["bosses"]], 17, Color("ffd54a"), 2)
	var pw := minf(820.0, W - 30)
	var x := W / 2 - pw / 2
	var y0 := 130.0
	var rh := 58.0
	m.scroll_max = maxf(0.0, hist.size() * rh - (H - y0 - 100))
	m.scroll = clampf(m.scroll, 0.0, m.scroll_max)
	if hist.is_empty():
		A.text_c(m, Vector2(W / 2, H / 2), "No runs yet. Your journeys will be recorded here.", 20, Color(0.8, 0.75, 0.9))
	for i in hist.size():
		var y: float = y0 + i * rh - m.scroll
		if y < y0 - rh or y > H - 90:
			continue
		var e: Dictionary = hist[i]
		var h := int(e["hero"])
		var col: Color = C.HEROES[h]["col"]
		var r := Rect2(x, y, pw, rh - 8)
		A.panel(m, r, Color(col.darkened(0.85), 0.9), Color(col, 0.6), 10, 2)
		A.hero(m, h, r.position + Vector2(30, 26), 40, m.t)
		A.text(m, r.position + Vector2(62, 22), C.HEROES[h]["name"], 19, col)
		A.text(m, r.position + Vector2(62, 42), str(e.get("date", "")), 13, Color(0.75, 0.7, 0.8))
		var res := "Victory" if e["won"] else "Fell in Act %s, floor %d" % [ROMAN[clampi(int(e["act"]) - 1, 0, 2)], int(e["floor"])]
		A.text(m, r.position + Vector2(pw * 0.3, 32), res, 17, Color("ffe27a") if e["won"] else Color("ff9a9a"))
		A.text(m, r.position + Vector2(pw - 140, 32), "Score %d" % int(e["score"]), 18, Color("ffd54a"))
	m.button(Rect2(20, H - 74, 150, 54), "Back", func(): m.go("title"), Color("9a8cb8"))


const HELP := [
	["Your goal", "Climb three acts - the Mirewood, the Glass Wastes and the Star Vault - and defeat the boss waiting at the top of each map. Every run is different: the map, the cards you are offered and the relics you find are random."],
	["Combat", "Each turn you get 3 Energy and draw 5 cards. Cards cost the Energy shown in their top-left gem. Drag a card up onto an enemy to play it (or tap a card, then tap the target). Skills and powers can be dropped anywhere above your hand. Press End Turn when you are done; your hand is discarded."],
	["Block and intents", "Block soaks up damage until the start of your next turn. The icon above each enemy shows its intent: a red blade means it will attack (with the damage shown), a blue shield means it will defend, a gold arrow means it will power up, a purple skull means it will curse you."],
	["Statuses", "Strength adds damage to attacks. Agility adds Block. Vulnerable takes 50% more damage. Sapped deals 25% less. Poison deals damage each turn and then drops by 1. Spikes hurt attackers. Hover or tap any status icon to read it."],
	["Between fights", "Pick a path on the map. Campfires let you Rest (heal) or Smith (upgrade a card). Merchants sell cards and relics and can remove a card. Mystery nodes hold events. Elites are tough but drop relics. Relics give permanent powers for the run."],
	["Controls", "Mouse or touch: drag cards, tap buttons, drag the map to scroll. Keyboard: 1-9 select a card, Tab cycles the target, Enter plays the selected card, E ends your turn, Esc pauses. Your run is saved every time you reach the map. Win runs and slay bosses to unlock new cards."],
]


func help() -> void:
	var W: float = m.W
	var H: float = m.H
	heading(56, "How to Play", 42)
	var pw := minf(820.0, W - 30)
	var x := W / 2 - pw / 2
	var y: float = 96.0 - m.scroll
	for i in HELP.size():
		var hdr: String = HELP[i][0]
		A.text(m, Vector2(x, y + 24), hdr, 24, Color("ffcf6a"), HORIZONTAL_ALIGNMENT_LEFT, -1, 2)
		var body: String = HELP[i][1]
		var lines: float = ceil(A.font().get_string_size(body, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x / (pw - 10)) + 1
		A.para(m, Vector2(x, y + 32), body, 18, Color("f4ead8"), pw, HORIZONTAL_ALIGNMENT_LEFT)
		y += 54 + lines * 25
	m.scroll_max = maxf(0.0, y + m.scroll - (H - 100))
	m.scroll = clampf(m.scroll, 0.0, m.scroll_max)
	m.draw_rect(Rect2(0, H - 90, W, 90), Color(0.04, 0.03, 0.08, 0.85))
	m.button(Rect2(20, H - 74, 150, 54), "Back", func(): m.go("title"), Color("9a8cb8"))


# ------------------------------------------------------------ overlays

func _dim() -> void:
	m.draw_rect(Rect2(0, 0, m.W, m.H), Color(0.02, 0.01, 0.05, 0.78))


func pause() -> void:
	_dim()
	var W: float = m.W
	var H: float = m.H
	var pw := 340.0
	var r := Rect2(W / 2 - pw / 2, H / 2 - 260, pw, 520)
	A.panel(m, r, Color(0.08, 0.05, 0.14, 0.97), Color("b49cff"), 18, 3)
	A.text_c(m, Vector2(W / 2, r.position.y + 44), "Paused", 36, Color("ffe9b8"), 3)
	var y := r.position.y + 80
	var x := r.position.x + 30
	var bw := pw - 60
	m.button(Rect2(x, y, bw, 52), "Resume", func(): m.overlay = "", Color("5ad18a"))
	y += 62
	m.button(Rect2(x, y, bw, 50), "View Deck", func(): m.open_cards("Your deck (%d cards)" % m.run.deck.size(), m.deck_list(), "view"), Color("7a5cff"))
	y += 60
	m.button(Rect2(x, y, bw, 50), "How to Play", func(): m.open_cards("", [], "help"), Color("7a5cff"))
	y += 60
	m.button(Rect2(x, y, bw / 2 - 5, 48), "Sound: " + ("On" if m.meta["sound"] else "Off"), m.toggle_sound, Color("6ab0ff"), true, 17)
	m.button(Rect2(x + bw / 2 + 5, y, bw / 2 - 5, 48), "Music: " + ("On" if m.meta["music"] else "Off"), m.toggle_music, Color("6ab0ff"), true, 17)
	y += 58
	m.button(Rect2(x, y, bw, 50), "Save & Quit to Title", m.to_title, Color("9a8cb8"))
	y += 60
	m.button(Rect2(x, y, bw, 50), "Abandon Run", func(): m.ask("Abandon this run? It will count as a loss.", m.abandon), Color("ff6a6a"))


func confirm() -> void:
	_dim()
	var W: float = m.W
	var H: float = m.H
	var r := Rect2(W / 2 - minf(220.0, W / 2 - 15), H / 2 - 100, minf(440.0, W - 30), 200)
	A.panel(m, r, Color(0.08, 0.05, 0.14, 0.97), Color("ff8a6a"), 16, 3)
	A.para(m, r.position + Vector2(20, 20), m.confirm_ov["text"], 20, Color("f4ead8"), r.size.x - 40)
	m.button(Rect2(r.position.x + 20, r.end.y - 70, r.size.x / 2 - 30, 52), "Yes", func(): m.overlay = ""; m.confirm_ov["yes"].call(), Color("ff6a6a"))
	m.button(Rect2(r.get_center().x + 10, r.end.y - 70, r.size.x / 2 - 30, 52), "No", func(): m.overlay = "pause" if m.run else "", Color("9a8cb8"))


func cards_overlay() -> void:
	_dim()
	var W: float = m.W
	var H: float = m.H
	var ov: Dictionary = m.cards_ov
	if ov["mode"] == "help":
		var y: float = 70.0 - m.scroll
		var pw := minf(760.0, W - 30)
		for i in HELP.size():
			A.text(m, Vector2(W / 2 - pw / 2, y), HELP[i][0], 22, Color("ffcf6a"), HORIZONTAL_ALIGNMENT_LEFT, -1, 2)
			var body: String = HELP[i][1]
			var lines: float = ceil(A.font().get_string_size(body, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x / (pw - 10)) + 1
			A.para(m, Vector2(W / 2 - pw / 2, y + 6), body, 17, Color("f4ead8"), pw, HORIZONTAL_ALIGNMENT_LEFT)
			y += 44 + lines * 24
		m.scroll_max = maxf(0.0, y + m.scroll - (H - 100))
		m.scroll = clampf(m.scroll, 0.0, m.scroll_max)
		m.draw_rect(Rect2(0, H - 86, W, 86), Color(0.02, 0.01, 0.05, 0.9))
		m.button(Rect2(W / 2 - 100, H - 72, 200, 54), "Close", func(): m.overlay = "pause", Color("9a8cb8"))
		return
	var list: Array = ov["list"]
	var sz := Vector2(150, 210)
	var gap := 14.0
	var cols := maxi(1, int((W - 30 + gap) / (sz.x + gap)))
	var x0 := W / 2 - (cols * sz.x + (cols - 1) * gap) / 2
	var y0 := 86.0
	var rows := int(ceil(list.size() / float(cols)))
	m.scroll_max = maxf(0.0, rows * (sz.y + gap) - (H - y0 - 96))
	m.scroll = clampf(m.scroll, 0.0, m.scroll_max)
	var sorted := list.duplicate()
	if ov["mode"] == "view":
		sorted.sort_custom(func(a, b): return [C.card(a["id"])["t"], C.card(a["id"])["c"], a["id"]] < [C.card(b["id"])["t"], C.card(b["id"])["c"], b["id"]])
	for i in sorted.size():
		var cd: Dictionary = sorted[i]
		var p := Vector2(x0 + (i % cols) * (sz.x + gap), y0 + (i / cols) * (sz.y + gap) - m.scroll)
		if p.y > H or p.y + sz.y < y0 - 10:
			continue
		var r := Rect2(p, sz)
		var h: bool = r.has_point(m.hover) and ov["mode"] != "view"
		A.card(m, p, cd["id"], cd["up"], m.t, sz, true, 0, false, h)
		if ov["mode"] != "view" and cd.has("i"):
			var cb: Callable = ov["cb"]
			m.hot(r, cb.bind(int(cd["i"])))
	m.draw_rect(Rect2(0, 0, W, 76), Color(0.02, 0.01, 0.05, 0.92))
	A.text_c(m, Vector2(W / 2, 40), ov["title"], 24 if not m.portrait else 19, Color("ffe9b8"), 3)
	m.draw_rect(Rect2(0, H - 86, W, 86), Color(0.02, 0.01, 0.05, 0.92))
	if list.is_empty():
		A.text_c(m, Vector2(W / 2, H / 2), "No cards here.", 22, Color(0.8, 0.75, 0.9))
	var back := "pause" if (m.screen != "battle" and false) else ""
	m.button(Rect2(W / 2 - 100, H - 72, 200, 54), "Close" if ov["mode"] == "view" else "Cancel", func(): m.overlay = back, Color("9a8cb8"))
