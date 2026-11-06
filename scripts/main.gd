extends Node2D
## Arcane Deck - screens, input, saving and juice. Everything is drawn in
## _draw() with code; buttons are rectangles registered while drawing.

const C := preload("res://scripts/cards.gd")
const D := preload("res://scripts/data.gd")
const A := preload("res://scripts/art.gd")
const Run := preload("res://scripts/run.gd")
const Battle := preload("res://scripts/battle.gd")
const BattleView := preload("res://scripts/battle_view.gd")
const Sfx := preload("res://scripts/sfx.gd")
const Screens := preload("res://scripts/screens.gd")
const META_PATH := "user://arcane_meta.json"
const RUN_PATH := "user://arcane_run.json"
const ROMAN := ["I", "II", "III"]

var sfx
var scr               # screens.gd helper
var bv                # battle_view.gd helper, while in combat
var screen := "title"
var overlay := ""     # "", "pause", "cards", "confirm"
var run = null
var meta := {"best": 0, "runs": 0, "wins": 0, "bosses": 0, "unlock": 0, "history": [], "sound": true, "music": true}
var t := 0.0
var W := 1280.0
var H := 720.0
var portrait := false
var buttons: Array = []
var tips: Array = []
var hover := Vector2(-999, -999)
var press_pos := Vector2.ZERO
var pressing := false
var dragged := false
var scroll := 0.0
var scroll_max := 0.0
var map_scroll := 0.0
var particles: Array = []
var floaters: Array = []
var shake_amt := 0.0
var shake_off := Vector2.ZERO
var fade := 1.0
var banner := ""
var banner_t := 0.0
var toast := ""
var toast_t := 0.0
var sticky_tip := ""
var sticky_t := 0.0
var sticky_pos := Vector2.ZERO
# screen data
var reward := {}
var event_i := 0
var event_result := ""
var shop_msg := ""
var end_info := {}
var cards_ov := {}    # {"title", "list": [{id, up, i}], "mode", "cb"}
var confirm_ov := {}
var pending := ""
var stars: Array = []
var title_cards: Array = []
var help_page := 0
var _js_cb


func _ready() -> void:
	randomize()
	sfx = Sfx.new()
	add_child(sfx)
	scr = Screens.new()
	scr.m = self
	_load_meta()
	sfx.sound_on = meta["sound"]
	for i in 140:
		stars.append(Vector3(randf(), randf(), randf_range(0.4, 1.0)))
	var ids := C.CARDS.keys()
	for i in 6:
		title_cards.append(ids[randi() % 60])
	_setup_js()


func _setup_js() -> void:
	if not OS.has_feature("web"):
		return
	_js_cb = JavaScriptBridge.create_callback(_on_js)
	var win = JavaScriptBridge.get_interface("window")
	win.arcaneCmd = _js_cb


func _on_js(args: Array) -> void:
	var r := test_cmd(str(args[0]) if args.size() > 0 else "state")
	JavaScriptBridge.eval("window.arcaneLast = " + JSON.stringify(r) + ";", true)


# ------------------------------------------------------------ persistence

func _load_meta() -> void:
	if not FileAccess.file_exists(META_PATH):
		return
	var f := FileAccess.open(META_PATH, FileAccess.READ)
	if f == null:
		return
	var d = JSON.parse_string(f.get_as_text())
	if d is Dictionary:
		for k in meta:
			if d.has(k):
				meta[k] = d[k]


func save_meta() -> void:
	var f := FileAccess.open(META_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(meta))


func save_run() -> void:
	if run == null or run.dead or run.won:
		return
	var d: Dictionary = run.to_dict()
	d["pending"] = pending
	var f := FileAccess.open(RUN_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d))


func clear_run_save() -> void:
	if FileAccess.file_exists(RUN_PATH):
		DirAccess.remove_absolute(RUN_PATH)


func has_save() -> bool:
	return FileAccess.file_exists(RUN_PATH)


func continue_run() -> void:
	var f := FileAccess.open(RUN_PATH, FileAccess.READ)
	if f == null:
		return
	var d = JSON.parse_string(f.get_as_text())
	if not d is Dictionary:
		clear_run_save()
		return
	run = Run.new()
	run.from_dict(d)
	pending = str(d.get("pending", ""))
	sfx.play("click")
	if pending != "":
		run.floor_n -= 1
		open_node(pending)
	else:
		go("map")


# ------------------------------------------------------------ flow

func go(s: String) -> void:
	screen = s
	overlay = ""
	scroll = 0.0
	fade = 0.0
	if s == "map":
		pending = ""
		save_run()
		map_scroll = -1.0
	if s in ["title", "heroes"]:
		sfx.set_music(meta["music"])


func new_run(h: int) -> void:
	run = Run.new()
	run.start(h, randi(), int(meta["unlock"]))
	clear_run_save()
	sfx.play("relic")
	go("map")
	show_banner("Act I: " + D.ACTS[0]["name"])


func enter_node(v: Vector2i) -> void:
	var kind: String = run.enter(v)
	sfx.play("click")
	pending = kind
	save_run()
	open_node(kind)


func open_node(kind: String) -> void:
	pending = kind
	match kind:
		"fight", "elite", "boss":
			start_battle(run.encounter(kind), kind)
		"rest":
			go("rest")
		"shop":
			run.make_shop()
			shop_msg = ""
			go("shop")
		"event":
			event_i = run.pick_event()
			event_result = ""
			go("event")
		"treasure":
			reward = {"relic": run.random_relic()}
			go("treasure")
	pending = kind
	save_run()


func start_battle(ids: Array, kind: String) -> void:
	var b := Battle.new()
	b.setup(run, ids, randi())
	bv = BattleView.new()
	bv.m = self
	bv.begin(b, kind)
	go("battle")
	pending = kind
	if kind == "boss":
		show_banner(D.ENEMIES[ids[0]]["n"])
	elif kind == "elite":
		show_banner("Elite: " + str(D.ENEMIES[ids[0]]["n"]))


func battle_over(b, kind: String) -> void:
	run.hp = maxi(0, b.p["hp"])
	run.stats["kills"] += b.kills
	run.stats["cards"] += b.cards_played
	run.stats["dmg"] += b.dmg_dealt
	if b.result != "win":
		finish_run(false)
		return
	if run.relics.has("ember_heart"):
		run.hp = mini(run.max_hp, run.hp + 6)
	var g: int = run.gold_reward("elite" if kind == "event_fight" else kind)
	run.gain_gold(g)
	reward = {"gold": g, "kind": kind, "cards": run.card_choices("elite" if kind == "event_fight" else kind), "relic": ""}
	if kind == "elite" or kind == "event_fight":
		run.stats["elites"] += 1
		var rel: String = run.random_relic()
		if rel != "":
			run.add_relic(rel)
			reward["relic"] = rel
	if kind == "boss":
		run.stats["bosses"] += 1
		meta["bosses"] = int(meta["bosses"]) + 1
	bv = null
	sfx.play("win")
	go("reward")


func reward_done() -> void:
	if reward.get("kind", "") == "boss":
		if run.act >= 2:
			finish_run(true)
		else:
			reward["boss_relics"] = run.boss_relic_choices()
			go("bossrelic")
	else:
		go("map")


func next_act() -> void:
	run.next_act()
	go("map")
	show_banner("Act %s: %s" % [ROMAN[run.act], D.ACTS[run.act]["name"]])


func finish_run(won: bool) -> void:
	run.won = won
	run.dead = not won
	bv = null
	clear_run_save()
	var sc: int = run.score()
	var old_unlock := int(meta["unlock"])
	meta["runs"] = int(meta["runs"]) + 1
	if won:
		meta["wins"] = int(meta["wins"]) + 1
	var best := sc > int(meta["best"])
	meta["best"] = maxi(sc, int(meta["best"]))
	meta["unlock"] = mini(4, int(meta["bosses"]))
	var hist: Array = meta["history"]
	hist.push_front({"hero": run.hero, "won": won, "act": run.act + 1, "floor": run.floor_n, "score": sc,
		"date": Time.get_date_string_from_system(), "kills": run.stats["kills"], "deck": run.deck.size()})
	while hist.size() > 25:
		hist.pop_back()
	meta["history"] = hist
	save_meta()
	var unlocked: Array = []
	for id in C.CARDS:
		var lk := int(C.CARDS[id].get("lock", 0))
		if lk > old_unlock and lk <= int(meta["unlock"]):
			unlocked.append(C.CARDS[id]["n"])
	end_info = {"won": won, "score": sc, "best": best, "unlocked": unlocked}
	sfx.play("win" if won else "lose")
	go("end")


func show_banner(s: String) -> void:
	banner = s
	banner_t = 2.2


func show_toast(s: String) -> void:
	toast = s
	toast_t = 2.0


func open_cards(title: String, list: Array, mode: String, cb := Callable()) -> void:
	cards_ov = {"title": title, "list": list, "mode": mode, "cb": cb}
	overlay = "cards"
	scroll = 0.0


func deck_list() -> Array:
	var out: Array = []
	for i in run.deck.size():
		out.append({"id": run.deck[i]["id"], "up": run.deck[i]["up"], "i": i})
	return out


func ask(text: String, yes: Callable) -> void:
	confirm_ov = {"text": text, "yes": yes}
	overlay = "confirm"


func toggle_sound() -> void:
	meta["sound"] = not meta["sound"]
	sfx.sound_on = meta["sound"]
	save_meta()
	sfx.play("click")


func toggle_music() -> void:
	meta["music"] = not meta["music"]
	sfx.set_music(meta["music"])
	save_meta()


func abandon() -> void:
	run.dead = true
	finish_run(false)


func to_title() -> void:
	save_run()
	bv = null
	go("title")


# ------------------------------------------------------------ juice

func burst(p: Vector2, col: Color, n := 14, spd := 260.0) -> void:
	for i in n:
		var a := randf() * TAU
		particles.append({"p": p, "v": Vector2(cos(a), sin(a)) * randf_range(spd * 0.3, spd), "life": randf_range(0.4, 0.9), "max": 0.9, "col": col, "s": randf_range(2.0, 5.0)})


func floater(p: Vector2, s: String, col: Color, size := 28) -> void:
	floaters.append({"p": p + Vector2(randf_range(-14, 14), 0), "s": s, "col": col, "life": 1.1, "size": size})


func shake(a: float) -> void:
	shake_amt = minf(18.0, shake_amt + a)


# ------------------------------------------------------------ main loop

func _process(delta: float) -> void:
	t += delta
	var ws := DisplayServer.window_get_size()
	var want := Vector2i(1280, 720) if ws.x >= ws.y else Vector2i(620, 1000)
	if get_tree().root.content_scale_size != want:
		get_tree().root.content_scale_size = want
	var vs := get_viewport_rect().size
	W = vs.x
	H = vs.y
	portrait = H > W * 1.15
	fade = minf(1.0, fade + delta * 3.5)
	banner_t = maxf(0.0, banner_t - delta)
	toast_t = maxf(0.0, toast_t - delta)
	sticky_t = maxf(0.0, sticky_t - delta)
	for p in particles:
		p["p"] += p["v"] * delta
		p["v"] *= 0.92
		p["v"].y += 240 * delta
		p["life"] -= delta
	particles = particles.filter(func(p): return p["life"] > 0)
	for f in floaters:
		f["p"].y -= 46 * delta
		f["life"] -= delta
	floaters = floaters.filter(func(f): return f["life"] > 0)
	shake_amt = maxf(0.0, shake_amt - delta * 40.0)
	shake_off = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake_amt
	if screen == "battle" and bv != null:
		bv.process(delta, overlay != "")
	queue_redraw()


func _draw() -> void:
	buttons.clear()
	tips.clear()
	draw_set_transform(shake_off)
	scr.background()
	match screen:
		"title":
			scr.title()
		"heroes":
			scr.heroes()
		"map":
			scr.map_screen()
		"battle":
			if bv:
				bv.draw()
		"reward":
			scr.reward_screen()
		"bossrelic":
			scr.boss_relic()
		"shop":
			scr.shop()
		"rest":
			scr.rest()
		"event":
			scr.event()
		"treasure":
			scr.treasure()
		"end":
			scr.end_screen()
		"history":
			scr.history()
		"help":
			scr.help()
	for p in particles:
		var k: float = p["life"] / p["max"]
		var pc: Color = p["col"]
		draw_circle(p["p"], p["s"] * (0.5 + k), Color(pc, minf(1.0, k * 1.5)))
	for f in floaters:
		var a := minf(1.0, f["life"] * 2.0)
		var fc: Color = f["col"]
		A.text_c(self, f["p"], f["s"], f["size"], Color(fc, a), 4)
	draw_set_transform(Vector2.ZERO)
	if overlay != "":
		buttons.clear()
		tips.clear()
		match overlay:
			"pause":
				scr.pause()
			"cards":
				scr.cards_overlay()
			"confirm":
				scr.confirm()
	if banner_t > 0:
		var a := minf(1.0, banner_t * 2.0) * minf(1.0, (2.2 - banner_t) * 4.0)
		draw_rect(Rect2(0, H * 0.4 - 46, W, 92), Color(0, 0, 0, 0.6 * a))
		A.text_c(self, Vector2(W / 2, H * 0.4), banner, 44 if not portrait else 36, Color(1, 0.92, 0.7, a), 6)
	if toast_t > 0:
		var a := minf(1.0, toast_t * 3.0)
		var tw := A.font().get_string_size(toast, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x + 40
		A.panel(self, Rect2(W / 2 - tw / 2, H - 300 if screen == "battle" else H - 90, tw, 44), Color(0.1, 0.06, 0.16, 0.92 * a), Color(1, 0.8, 0.4, a), 10)
		A.text_c(self, Vector2(W / 2, (H - 278) if screen == "battle" else H - 68), toast, 20, Color(1, 1, 1, a))
	_draw_tip()
	if fade < 1.0:
		draw_rect(Rect2(0, 0, W, H), Color(0.04, 0.03, 0.08, 1.0 - fade))


func _draw_tip() -> void:
	var s := ""
	var at := hover
	if sticky_t > 0:
		s = sticky_tip
		at = sticky_pos
	else:
		for tp in tips:
			if tp["r"].has_point(hover):
				s = tp["s"]
	if s == "":
		return
	var w := minf(340.0, W - 20)
	var lines := s.split("\n")
	var f := A.font()
	var h := 16.0
	for ln in lines:
		var lw := f.get_string_size(ln, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
		h += 22.0 * maxf(1.0, ceil(lw / (w - 24)))
	var p := at + Vector2(16, 18)
	p.x = clampf(p.x, 10, W - w - 10)
	if p.y + h > H - 10:
		p.y = at.y - h - 14
	A.panel(self, Rect2(p, Vector2(w, h)), Color(0.08, 0.05, 0.13, 0.96), Color("ffcf6a"), 8)
	draw_multiline_string(f, p + Vector2(12, 26), s, HORIZONTAL_ALIGNMENT_LEFT, w - 24, 17, -1, Color("f4ead8"))


# ------------------------------------------------------------ widgets

func button(r: Rect2, label: String, cb: Callable, col := Color("7a5cff"), enabled := true, fs := 21) -> void:
	var hot := enabled and r.has_point(hover)
	var bg := col.darkened(0.35 if hot else 0.62) if enabled else Color(0.16, 0.14, 0.2)
	if hot:
		A.panel(self, r.grow(3), Color(col, 0.25), Color(col, 0.0), 12, 0)
	A.panel(self, r, bg, col.lightened(0.35) if hot else (col if enabled else Color(0.35, 0.32, 0.4)), 10, 2)
	A.text_c(self, r.get_center(), label, fs, Color.WHITE if enabled else Color(0.6, 0.58, 0.65), 2)
	buttons.append({"r": r, "cb": cb, "en": enabled})


func hot(r: Rect2, cb: Callable) -> void:
	buttons.append({"r": r, "cb": cb, "en": true})


func tip(r: Rect2, s: String) -> void:
	tips.append({"r": r, "s": s})


func icon_button(r: Rect2, kind: String, cb: Callable) -> void:
	var h := r.has_point(hover)
	A.panel(self, r, Color(0.15, 0.1, 0.24) if not h else Color(0.28, 0.2, 0.42), Color("b49cff"), 10, 2)
	var c := r.get_center()
	match kind:
		"pause":
			draw_rect(Rect2(c + Vector2(-9, -11), Vector2(6, 22)), Color.WHITE)
			draw_rect(Rect2(c + Vector2(3, -11), Vector2(6, 22)), Color.WHITE)
		"deck":
			A.card_back(self, c + Vector2(-11, -14), Vector2(18, 26), Color("b49cff"))
			A.card_back(self, c + Vector2(-5, -11), Vector2(18, 26), Color("ffcf6a"))
	hot(r, cb)


## Top bar shown on map, battle and the node screens.
func hud() -> float:
	var hh := 64.0 if not portrait else 108.0
	draw_rect(Rect2(0, 0, W, hh), Color(0.05, 0.03, 0.09, 0.88))
	draw_line(Vector2(0, hh), Vector2(W, hh), Color("b49cff", 0.6), 2)
	var hd: Dictionary = C.HEROES[run.hero]
	var x := 14.0
	A.text(self, Vector2(x, 26), hd["name"], 22, hd["col"], HORIZONTAL_ALIGNMENT_LEFT, -1, 2)
	A.text(self, Vector2(x, 50), hd["title"], 14, Color(0.8, 0.75, 0.85))
	x += 150
	var hp: int = bv.b.p["hp"] if (screen == "battle" and bv != null) else run.hp
	A.heart(self, Vector2(x, 32), 13)
	A.text(self, Vector2(x + 20, 40), "%d/%d" % [hp, run.max_hp], 22, Color("ff8a9a"), HORIZONTAL_ALIGNMENT_LEFT, -1, 2)
	tip(Rect2(x - 14, 10, 110, 44), "Health. If it reaches 0 the run ends.")
	x += 120
	A.coin(self, Vector2(x, 32), 12)
	A.text(self, Vector2(x + 18, 40), str(run.gold), 22, Color("ffd54a"), HORIZONTAL_ALIGNMENT_LEFT, -1, 2)
	tip(Rect2(x - 14, 10, 80, 44), "Gold. Spend it at the Merchant.")
	x += 84
	if not portrait:
		A.text(self, Vector2(x, 28), "Act %s  -  %s" % [ROMAN[run.act], D.ACTS[run.act]["name"]], 17, D.ACTS[run.act]["acc"])
		A.text(self, Vector2(x, 50), "Floor %d" % run.floor_n, 15, Color(0.8, 0.78, 0.86))
		x += 230
	# relics
	var rx := x
	var ry := 32.0
	if portrait:
		rx = 16.0
		ry = 84.0
		A.text(self, Vector2(W - 210, 92), "Act %s  Floor %d" % [ROMAN[run.act], run.floor_n], 16, D.ACTS[run.act]["acc"])
	var maxr := int((W - rx - (130 if not portrait else 230)) / 38)
	for i in mini(run.relics.size(), maxr):
		var id: String = run.relics[i]
		var c := Vector2(rx + 17 + i * 38, ry)
		A.relic(self, id, c, 32, t)
		var rr := Rect2(c - Vector2(17, 17), Vector2(34, 34))
		tip(rr, D.RELICS[id]["n"] + "\n" + D.RELICS[id]["d"])
		hot(rr, sticky.bind(D.RELICS[id]["n"] + "\n" + D.RELICS[id]["d"], c))
	icon_button(Rect2(W - 120, 10, 50, 44), "deck", func(): open_cards("Your deck (%d cards)" % run.deck.size(), deck_list(), "view"))
	tip(Rect2(W - 120, 10, 50, 44), "View your deck (%d cards)" % run.deck.size())
	icon_button(Rect2(W - 62, 10, 50, 44), "pause", func(): overlay = "pause"; sfx.play("click"))
	return hh


func sticky(s: String, p: Vector2) -> void:
	sticky_tip = s
	sticky_pos = p
	sticky_t = 2.6


# ------------------------------------------------------------ input

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouse:
		var ev := make_input_local(event) as InputEventMouse
		var p: Vector2 = ev.position
		if ev is InputEventMouseMotion:
			hover = p
			if pressing and p.distance_to(press_pos) > 12:
				dragged = true
			if pressing and dragged and overlay == "" and not (screen == "battle" and bv and bv.dragging()):
				var dy: float = (ev as InputEventMouseMotion).relative.y
				if screen == "map":
					map_scroll += dy
				else:
					scroll -= dy
			if screen == "battle" and bv and overlay == "":
				bv.motion(p)
		elif ev is InputEventMouseButton:
			var mb := ev as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				if mb.pressed:
					var dir := -1.0 if mb.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0
					if screen == "map" and overlay == "":
						map_scroll -= dir * 60
					else:
						scroll += dir * 60
				return
			if mb.button_index != MOUSE_BUTTON_LEFT:
				return
			hover = p
			if mb.pressed:
				pressing = true
				dragged = false
				press_pos = p
				if screen == "battle" and bv and overlay == "":
					if bv.press(p):
						return
			else:
				pressing = false
				if screen == "battle" and bv and overlay == "" and bv.dragging():
					bv.release(p)
					return
				if not dragged or p.distance_to(press_pos) < 14:
					click(p)
	elif event is InputEventKey and event.pressed and not event.echo:
		key(event.keycode)


func click(p: Vector2) -> void:
	for i in range(buttons.size() - 1, -1, -1):
		var b: Dictionary = buttons[i]
		if b["r"].has_point(p):
			if b["en"]:
				b["cb"].call()
			else:
				sfx.play("deny")
			return
	if screen == "battle" and bv and overlay == "":
		bv.tap(p)


func key(k: int) -> void:
	if k == KEY_ESCAPE:
		if overlay == "cards" and cards_ov["mode"] == "view":
			overlay = ""
		elif overlay != "":
			overlay = "" if overlay != "cards" else overlay
		elif screen in ["map", "battle", "shop", "rest", "event", "reward", "treasure", "bossrelic"]:
			overlay = "pause"
		elif screen in ["history", "help", "heroes"]:
			go("title")
		return
	if screen == "battle" and bv and overlay == "":
		bv.key(k)


# ------------------------------------------------------------ test hook

## Small command interface for automated tests (headless + browser).
func test_cmd(cmd: String) -> Dictionary:
	var parts := cmd.split(":")
	var c := parts[0]
	match c:
		"new":
			new_run(int(parts[1]) if parts.size() > 1 else 0)
		"node":
			var av: Array = run.available()
			var want := parts[1] if parts.size() > 1 else ""
			var pick: Vector2i = av[0]
			for v in av:
				if want != "" and run.node_type(v) == want:
					pick = v
			enter_node(pick)
		"play":
			if bv:
				bv.auto_play_one()
		"end":
			if bv:
				bv.end_turn()
		"win":
			if bv:
				for e in bv.b.enemies:
					e["hp"] = 1
				bv.auto_play_one()
		"take":
			if screen == "reward":
				scr.take_card(0)
			elif screen == "treasure":
				scr.take_treasure()
			elif screen == "bossrelic":
				scr.pick_boss_relic(0)
		"skip":
			reward_done()
		"lose":
			if bv:
				bv.b.p["hp"] = 1
				bv.b.p["block"] = 0
				for e in bv.b.enemies:
					e["intent"] = {"n": "Test", "fx": [["atk", 99]]}
				bv.end_turn()
		"go":
			go(parts[1])
		"overlay":
			overlay = parts[1] if parts.size() > 1 else ""
		"deck":
			open_cards("Your deck", deck_list(), "view")
		"event":
			if screen == "event":
				scr.choose_event(int(parts[1]) if parts.size() > 1 else 0)
		"rest":
			if screen == "rest":
				scr.do_rest()
	var st := {"screen": screen, "overlay": overlay, "t": t}
	if c == "shot":
		var img := get_viewport().get_texture().get_image()
		var w := mini(900, img.get_width())
		img.resize(w, int(img.get_height() * float(w) / img.get_width()), Image.INTERPOLATE_BILINEAR)
		st["jpg"] = Marshalls.raw_to_base64(img.save_jpg_to_buffer(0.72))
	if run:
		st["hp"] = run.hp
		st["act"] = run.act
		st["floor"] = run.floor_n
		st["gold"] = run.gold
		st["deck"] = run.deck.size()
	if bv:
		st["bhp"] = bv.b.p["hp"]
		st["hand"] = bv.b.hand.size()
		st["over"] = bv.b.over
		st["phase"] = bv.b.phase
		st["enemies"] = bv.b.alive_enemies().size()
	return st
