extends RefCounted
## Arcane Deck - the combat screen: layout, drag-to-play hand, targeting,
## enemy turn sequencing and all the hit / block / status feedback.

const C := preload("res://scripts/cards.gd")
const D := preload("res://scripts/data.gd")
const A := preload("res://scripts/art.gd")
const CS := Vector2(150, 210)

var m
var b
var kind := "fight"
var cpos := {}        # uid -> animated card position (center)
var ex := {}          # enemy uid -> animated x
var eflash := {}
var elunge := {}
var edeath := {}
var pflash := 0.0
var plunge := 0.0
var drag := {}
var selected := -1
var target_i := 0
var eq := 0
var etimer := 0.0
var end_t := 0.0
var done := false
var flying: Array = []
var turn_text := ""
var turn_t := 0.0
var hover_card := -1


func begin(battle, k: String) -> void:
	b = battle
	kind = k
	_consume()
	turn_text = "Your turn"
	turn_t = 1.2


# ------------------------------------------------------------ layout

func hud_h() -> float:
	return 64.0 if not m.portrait else 108.0


func player_c() -> Vector2:
	if m.portrait:
		return Vector2(m.W * 0.3, m.H * 0.56)
	return Vector2(m.W * 0.2, m.H * 0.47)


func hand_y() -> float:
	return m.H - (222.0 if not m.portrait else 252.0)


func orb_c() -> Vector2:
	if m.portrait:
		return Vector2(m.W - 84, m.H * 0.53)
	return Vector2(70, m.H - 168)


func end_rect() -> Rect2:
	if m.portrait:
		return Rect2(m.W - 170, m.H * 0.53 + 66, 150, 58)
	return Rect2(m.W - 186, m.H - 300, 166, 60)


func draw_pile_c() -> Vector2:
	if m.portrait:
		return Vector2(38, hand_y() - 40)
	return Vector2(52, m.H - 56)


func discard_c() -> Vector2:
	if m.portrait:
		return Vector2(m.W - 38, hand_y() - 40)
	return Vector2(m.W - 52, m.H - 56)


func visible_enemies() -> Array:
	var out: Array = []
	for i in b.enemies.size():
		var e: Dictionary = b.enemies[i]
		if e["alive"] or float(edeath.get(e["uid"], 0.0)) > 0.0:
			out.append(i)
	return out


func enemy_layout() -> Dictionary:
	var vis := visible_enemies()
	var left: float = m.W * 0.42 if not m.portrait else 14.0
	var right: float = m.W * 0.97 if not m.portrait else m.W - 14.0
	var y: float = m.H * 0.45 if not m.portrait else hud_h() + 250.0
	var slot: float = (right - left) / maxf(1.0, vis.size())
	var out := {}
	for j in vis.size():
		var i: int = vis[j]
		var e: Dictionary = b.enemies[i]
		var sz: float = D.ENEMIES[e["id"]]["sz"]
		var k := minf(1.0 if not m.portrait else 1.3, slot * 0.9 / (125.0 * sz))
		if m.portrait:
			k = minf(k, 1.0 if sz < 1.6 else 0.85)
		var tx: float = left + slot * (j + 0.5)
		var cx: float = ex.get(e["uid"], tx)
		out[i] = {"c": Vector2(cx, y + (1.0 - k) * 30.0), "k": k, "s": 120.0 * sz * k, "tx": tx}
	return out


func enemy_rect(lay: Dictionary) -> Rect2:
	var s: float = lay["s"]
	return Rect2(lay["c"] - Vector2(s * 0.5, s * 0.62), Vector2(s, s * 1.15))


func hand_targets() -> Array:
	var n: int = b.hand.size()
	var out: Array = []
	var left := 140.0 if not m.portrait else 8.0
	var right: float = m.W - 140.0 if not m.portrait else m.W - 8.0
	if not m.portrait:
		left = maxf(left, 150.0)
	var span: float = right - left - CS.x
	var sp := minf(CS.x * 0.95, span / maxf(1.0, n - 1)) if n > 1 else 0.0
	var total := sp * (n - 1)
	var x0: float = (left + right) / 2.0 - total / 2.0
	var mid := (n - 1) / 2.0
	for i in n:
		var d := i - mid
		out.append({"c": Vector2(x0 + i * sp, hand_y() + CS.y / 2 + d * d * 2.2), "rot": d * 0.045})
	return out


func card_at(p: Vector2) -> int:
	var ht := hand_targets()
	var best := -1
	for i in b.hand.size():
		var c: Vector2 = cpos.get(b.hand[i]["uid"], ht[i]["c"])
		var r := Rect2(c - CS / 2 - Vector2(0, 40 if i == hover_card else 0), CS + Vector2(0, 40 if i == hover_card else 0))
		if r.has_point(p):
			best = i
	if hover_card >= 0 and hover_card < b.hand.size():
		var hc: Vector2 = cpos.get(b.hand[hover_card]["uid"], Vector2.ZERO)
		if Rect2(hc - CS * 0.6 - Vector2(0, 50), CS * 1.2 + Vector2(0, 50)).has_point(p):
			return hover_card
	return best


func enemy_at(p: Vector2) -> int:
	var lay := enemy_layout()
	for i in lay:
		if b.enemies[i]["alive"] and enemy_rect(lay[i]).grow(12).has_point(p):
			return i
	return -1


# ------------------------------------------------------------ actions

func playable(hi: int) -> bool:
	var err: String = b.can_play(hi, -1)
	return err == "" or err == "Choose a target"


func targeted(hi: int) -> bool:
	return hi >= 0 and hi < b.hand.size() and C.needs_target(b.hand[hi]["id"])


func do_play(hi: int, ti: int) -> bool:
	if hi < 0 or hi >= b.hand.size():
		return false
	var cd: Dictionary = b.hand[hi]
	var from: Vector2 = cpos.get(cd["uid"], Vector2(m.W / 2, m.H - 100))
	var err: String = b.play(hi, ti)
	if err != "":
		m.sfx.play("deny")
		m.show_toast(err)
		return false
	var lay := enemy_layout()
	var to := Vector2(m.W / 2, m.H * 0.4)
	if ti >= 0 and lay.has(ti):
		to = lay[ti]["c"]
	elif C.card(cd["id"])["t"] != 0:
		to = player_c()
	flying.append({"id": cd["id"], "up": cd["up"], "from": from, "to": to, "t": 0.0})
	cpos.erase(cd["uid"])
	m.sfx.play("card")
	plunge = 0.25 if C.card(cd["id"])["t"] == 0 else 0.0
	selected = -1
	_consume()
	return true


func end_turn() -> void:
	if b.over or b.phase != "player":
		return
	b.end_player_turn()
	selected = -1
	drag = {}
	eq = 0
	etimer = 0.45
	turn_text = "Enemy turn"
	turn_t = 1.0
	m.sfx.play("turn", 0.8)
	_consume()


func auto_play_one() -> void:
	if b.over or b.phase != "player":
		return
	for i in b.hand.size():
		if playable(i):
			var ti := -1
			if targeted(i):
				ti = b.alive_enemies()[0]
			if do_play(i, ti):
				return
	end_turn()


# ------------------------------------------------------------ input

func dragging() -> bool:
	return not drag.is_empty()


func press(p: Vector2) -> bool:
	if b.over or b.phase != "player":
		return false
	if end_rect().has_point(p):
		return false
	var hi := card_at(p)
	if hi < 0:
		return false
	drag = {"hi": hi, "uid": b.hand[hi]["uid"], "start": p, "pos": p, "moved": false}
	return true


func motion(p: Vector2) -> void:
	if drag.is_empty():
		var hc := card_at(p) if (b.phase == "player" and not b.over) else -1
		hover_card = hc
		return
	drag["pos"] = p
	if p.distance_to(drag["start"]) > 14:
		drag["moved"] = true
		selected = drag["hi"]


func release(p: Vector2) -> void:
	var d := drag
	drag = {}
	if d.is_empty():
		return
	var hi: int = d["hi"]
	if hi >= b.hand.size() or b.hand[hi]["uid"] != d["uid"]:
		return
	if not d["moved"]:
		_tap_card(hi)
		return
	if targeted(hi):
		var ei := enemy_at(p)
		if ei < 0 and b.alive_enemies().size() == 1 and p.y < hand_y() - 40:
			ei = b.alive_enemies()[0]
		if ei >= 0:
			do_play(hi, ei)
		else:
			selected = -1
	elif p.y < hand_y() - 30:
		do_play(hi, -1)
	else:
		selected = -1


func _tap_card(hi: int) -> void:
	if selected == hi:
		if not targeted(hi):
			do_play(hi, -1)
		elif b.alive_enemies().size() == 1:
			do_play(hi, b.alive_enemies()[0])
		else:
			m.show_toast("Tap an enemy to target it")
	else:
		selected = hi
		m.sfx.play("draw")
		if not playable(hi):
			m.show_toast(b.can_play(hi, -1))


func tap(p: Vector2) -> void:
	if b.over:
		return
	if selected >= 0 and selected < b.hand.size() and not targeted(selected) and p.y < hand_y() - 20:
		do_play(selected, -1)
		return
	var ei := enemy_at(p)
	if ei >= 0:
		target_i = ei
		if selected >= 0 and targeted(selected):
			do_play(selected, ei)
			return
		m.sticky(_enemy_tip(ei), p)
		return
	if selected >= 0 and not targeted(selected) and p.y < hand_y() - 20:
		do_play(selected, -1)
		return
	selected = -1


func key(k: int) -> void:
	if b.over:
		return
	if k >= KEY_1 and k <= KEY_9:
		var i := k - KEY_1
		if i < b.hand.size():
			selected = i
			m.sfx.play("draw")
	elif k == KEY_0 and b.hand.size() >= 10:
		selected = 9
	elif k == KEY_TAB:
		var al: Array = b.alive_enemies()
		if not al.is_empty():
			var j := al.find(target_i)
			target_i = al[(j + 1) % al.size()]
	elif k == KEY_ENTER or k == KEY_KP_ENTER or k == KEY_SPACE:
		if selected >= 0:
			var al: Array = b.alive_enemies()
			if not al.has(target_i) and not al.is_empty():
				target_i = al[0]
			do_play(selected, target_i if targeted(selected) else -1)
	elif k == KEY_E:
		end_turn()


# ------------------------------------------------------------ update

func process(delta: float, paused: bool) -> void:
	var f := 1.0 - exp(-14.0 * delta)
	var ht := hand_targets()
	for i in b.hand.size():
		var uid: int = b.hand[i]["uid"]
		var tgt: Vector2 = ht[i]["c"]
		if i == selected or i == hover_card:
			tgt.y -= 46 if i == selected else 36
		if not cpos.has(uid):
			cpos[uid] = draw_pile_c()
		cpos[uid] = cpos[uid].lerp(tgt, f)
	var lay := enemy_layout()
	for i in lay:
		var uid: int = b.enemies[i]["uid"]
		ex[uid] = lerpf(float(ex.get(uid, lay[i]["tx"])), lay[i]["tx"], f * 0.5)
	for k in eflash.keys():
		eflash[k] = maxf(0.0, eflash[k] - delta * 4.0)
	for k in elunge.keys():
		elunge[k] = maxf(0.0, elunge[k] - delta * 2.5)
	for k in edeath.keys():
		edeath[k] = maxf(0.0, edeath[k] - delta * 1.4)
	pflash = maxf(0.0, pflash - delta * 4.0)
	plunge = maxf(0.0, plunge - delta * 2.0)
	turn_t = maxf(0.0, turn_t - delta)
	for fl in flying:
		fl["t"] += delta * 3.2
	flying = flying.filter(func(fl): return fl["t"] < 1.0)
	if paused:
		return
	if b.phase == "enemy" and not b.over:
		etimer -= delta
		if etimer <= 0:
			if eq < b.enemies.size():
				var i := eq
				eq += 1
				if b.enemies[i]["alive"]:
					b.enemy_act(i)
					etimer = 0.62
				else:
					etimer = 0.0
			else:
				b.end_enemy_phase()
				turn_text = "Your turn"
				turn_t = 1.0
				m.sfx.play("turn")
		_consume()
	if b.over and not done:
		end_t += delta
		if end_t > 1.3:
			done = true
			m.battle_over(b, kind)


func _consume() -> void:
	var lay := enemy_layout()
	for ev in b.events:
		var who: int = ev.get("who", -2)
		var at := player_c() + Vector2(0, -90)
		if who >= 0 and lay.has(who):
			at = lay[who]["c"] + Vector2(0, -lay[who]["s"] * 0.4)
		match ev["t"]:
			"hit":
				var amt: int = ev["amt"]
				var blocked: int = ev.get("blocked", 0)
				var k: String = ev.get("kind", "hit")
				if who < 0:
					if amt > 0:
						m.floater(at, "-%d" % amt, Color("ff9a3a") if k == "self" else (Color("8cff5a") if k == "poison" else Color("ff5a5a")), 34)
						pflash = 1.0
						m.shake(4.0 + amt * 0.4)
						m.burst(player_c(), Color("ff4a5a"), 8 + amt)
						m.sfx.play("big_hit" if amt >= 15 else "hit")
					if blocked > 0:
						m.floater(at + Vector2(0, 30), "Blocked %d" % blocked, Color("8cc8ff"), 22)
						m.sfx.play("block")
					if ev.has("src"):
						var su: int = b.enemies[ev["src"]]["uid"]
						elunge[su] = 1.0
				else:
					var uid: int = b.enemies[who]["uid"]
					if amt > 0:
						eflash[uid] = 1.0
						m.floater(at, str(amt), Color("8cff5a") if k == "poison" else Color("fff0c0"), 36 if amt < 20 else 46)
						m.burst(at + Vector2(0, 30), Color("8cff5a") if k == "poison" else Color("ffcf6a"), 6 + mini(30, amt))
						m.shake(1.5 + amt * 0.18)
						m.sfx.play("poison" if k == "poison" else ("big_hit" if amt >= 18 else "hit"))
					if blocked > 0:
						m.floater(at + Vector2(0, 26), "Blocked %d" % blocked, Color("8cc8ff"), 20)
			"block":
				m.floater(at + Vector2(0, 20), "+%d Block" % ev["amt"], Color("8cc8ff"), 24)
				m.sfx.play("block")
			"status":
				var st: String = ev["st"]
				var sd: Dictionary = C.STATUS.get(st, {"n": st, "col": Color.WHITE, "good": true})
				m.floater(at + Vector2(0, -10), "%+d %s" % [ev["n"], sd["n"]], sd["col"], 22)
				m.sfx.play("buff" if sd["good"] == (who < 0) else "debuff")
			"heal":
				m.floater(at, "+%d" % ev["amt"], Color("6aff8a"), 30)
				m.sfx.play("heal")
			"die":
				var uid: int = b.enemies[who]["uid"]
				edeath[uid] = 1.0
				m.burst(at + Vector2(0, 40), D.ENEMIES[b.enemies[who]["id"]]["col"], 40, 380)
				m.sfx.play("die")
				m.shake(6)
			"move":
				m.floater(at + Vector2(0, -40), ev["n"], Color("ffe9b8"), 22)
			"relic":
				m.floater(player_c() + Vector2(0, -150), D.RELICS[ev["id"]]["n"] + "!", Color("ffcf6a"), 24)
				m.sfx.play("relic")
			"power":
				m.floater(player_c() + Vector2(0, -150), C.POWERS[ev["id"]]["n"], Color("ffe27a"), 26)
				m.sfx.play("buff")
			"energy":
				m.floater(orb_c() + Vector2(0, -50), "+%d Energy" % ev["amt"], Color("ffe27a"), 22)
			"shuffle":
				m.sfx.play("draw")
			"summon":
				m.burst(at + Vector2(0, 40), Color("8cffd0"), 24)
			"doubt":
				m.floater(player_c() + Vector2(0, -120), "Hollow Doubt x%d" % ev["n"], Color("c08cff"), 22)
	b.events.clear()


# ------------------------------------------------------------ drawing

func _enemy_tip(i: int) -> String:
	var e: Dictionary = b.enemies[i]
	var s: String = e["n"] + "  (%d/%d HP)\nIntends to %s" % [e["hp"], e["max_hp"], b.intent_text(i).split(": will ")[1] if ": will " in b.intent_text(i) else "act"]
	for st in e["st"]:
		if C.STATUS.has(st):
			s += "\n%s %d: %s" % [C.STATUS[st]["n"], e["st"][st], C.STATUS[st]["d"]]
	return s


func _bar(c: Vector2, w: float, hp: int, mx: int, block: int) -> void:
	var r := Rect2(c.x - w / 2, c.y, w, 14)
	m.draw_rect(r.grow(2), Color(0, 0, 0, 0.7))
	m.draw_rect(Rect2(r.position, Vector2(w * clampf(float(hp) / maxf(1, mx), 0, 1), 14)), Color("e8344a") if block == 0 else Color("4a8aff"))
	A.text_c(m, r.get_center() + Vector2(0, 1), "%d/%d" % [hp, mx], 13, Color.WHITE, 2)
	if block > 0:
		var bc := Vector2(r.position.x - 6, r.get_center().y)
		A.motif(m, "shield", bc, 34, Color("6ab0ff"))
		A.text_c(m, bc + Vector2(0, -1), str(block), 15, Color.WHITE, 3)


func _statuses(c: Vector2, st: Dictionary, pw := {}) -> void:
	var keys: Array = st.keys()
	var x := c.x - (keys.size() + pw.size()) * 15.0 + 15.0
	for s in keys:
		var p := Vector2(x, c.y)
		A.status_icon(m, s, p, 26, m.t)
		A.text(m, p + Vector2(4, 13), str(st[s]), 14, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, -1, 3)
		var r := Rect2(p - Vector2(14, 14), Vector2(28, 28))
		if C.STATUS.has(s):
			var tx: String = "%s %d\n%s" % [C.STATUS[s]["n"], st[s], C.STATUS[s]["d"]]
			m.tip(r, tx)
			m.hot(r, m.sticky.bind(tx, p))
		x += 30
	for s in pw:
		var p := Vector2(x, c.y)
		m.draw_circle(p, 13, Color(0.2, 0.12, 0.3))
		m.draw_arc(p, 13, 0, TAU, 20, Color("ffe27a"), 2)
		A.motif(m, "star", p, 20, Color("ffe27a"), m.t)
		A.text(m, p + Vector2(4, 13), str(pw[s]), 14, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, -1, 3)
		var tx: String = "Power - %s\n%s" % [C.POWERS[s]["n"], C.POWERS[s]["d"].replace("N", str(pw[s]))]
		var r := Rect2(p - Vector2(14, 14), Vector2(28, 28))
		m.tip(r, tx)
		m.hot(r, m.sticky.bind(tx, p))
		x += 30


func draw() -> void:
	var W: float = m.W
	var H: float = m.H
	var t: float = m.t
	var acc: Color = D.ACTS[m.run.act]["acc"]
	# ground
	var gy: float = (m.H * 0.47 + 70) if not m.portrait else hud_h() + 330.0
	m.draw_rect(Rect2(-20, gy, W + 40, H - gy + 20), Color(0, 0, 0, 0.28))
	m.draw_line(Vector2(-20, gy), Vector2(W + 20, gy), Color(acc, 0.3), 2)
	if m.portrait:
		var py := player_c().y + 90
		m.draw_rect(Rect2(-20, py, W + 40, 4), Color(acc, 0.2))
	# player
	var pc := player_c() + Vector2(plunge * 60.0, 0)
	A.glow_circle(m, pc, 120, Color(C.HEROES[m.run.hero]["col"], 0.5))
	A.hero(m, m.run.hero, pc, 190 if not m.portrait else 170, t, pflash)
	var p: Dictionary = b.p
	_bar(player_c() + Vector2(0, 108), 150, p["hp"], p["max_hp"], p["block"])
	_statuses(player_c() + Vector2(0, 146), p["st"], p["pw"])
	# enemies
	var lay := enemy_layout()
	var drag_target := -1
	if not drag.is_empty() and drag["moved"] and targeted(drag["hi"]):
		drag_target = enemy_at(drag["pos"])
	var sel_target := selected >= 0 and targeted(selected)
	for i in lay:
		var e: Dictionary = b.enemies[i]
		var L: Dictionary = lay[i]
		var c: Vector2 = L["c"]
		var k: float = L["k"]
		var s: float = L["s"]
		var uid: int = e["uid"]
		var dying: bool = not e["alive"]
		var lunge: float = elunge.get(uid, 0.0)
		var off := Vector2(-sin(lunge * PI) * 50.0, 0) if not m.portrait else Vector2(0, sin(lunge * PI) * 40.0)
		var a := 1.0 if not dying else float(edeath.get(uid, 0.0))
		if a <= 0.0:
			continue
		if (drag_target == i) or (sel_target and target_i == i and drag.is_empty()):
			A.glow_circle(m, c, s * 0.8, Color("ff5a4a"), 5)
			m.draw_arc(c + Vector2(0, s * 0.5), s * 0.45, 0, TAU, 32, Color("ff8a6a"), 3)
		m.draw_set_transform(m.shake_off + c + off, 0, Vector2(k, k) * (1.0 if not dying else 0.6 + 0.4 * a))
		A.enemy(m, e["id"], Vector2.ZERO, t, eflash.get(uid, 0.0) if not dying else 1.0 - a)
		m.draw_set_transform(m.shake_off)
		var r := enemy_rect(L)
		if dying:
			continue
		m.tip(r, _enemy_tip(i))
		_bar(Vector2(c.x, c.y + s * 0.6 + 6), clampf(s * 0.9, 100, 170), e["hp"], e["max_hp"], e["block"])
		_statuses(Vector2(c.x, c.y + s * 0.6 + 42), e["st"])
		# intent
		var inf: Dictionary = b.intent_info(i)
		var ic := Vector2(c.x, c.y - s * 0.62 - 26 + sin(t * 3 + i) * 3)
		var kinds: Array = inf["kinds"]
		var ix := ic.x - (kinds.size() - 1) * 18.0
		for kd in kinds:
			A.intent_icon(m, kd, Vector2(ix, ic.y), 34, t)
			if kd == "atk":
				var lbl := str(inf["dmg"]) + (("x%d" % inf["times"]) if inf["times"] > 1 else "")
				A.text_c(m, Vector2(ix, ic.y + 22), lbl, 20, Color("ffd0c0"), 3)
			ix += 36
		var irr := Rect2(ic - Vector2(40, 22), Vector2(80, 48))
		m.tip(irr, b.intent_text(i))
		A.text_c(m, Vector2(c.x, c.y + s * 0.6 + (42 if e["st"].is_empty() else 72)), e["n"], 14, Color(0.85, 0.8, 0.9), 2)
	# energy orb, piles, end turn
	var oc := orb_c()
	A.energy_orb(m, oc, 40, p["energy"], 3 + int(p["pw"].get("font", 0)) + (1 if b.has_relic("sun_engine") else 0) + (1 if b.has_relic("crown_of_ash") else 0), Color("ffcf4a"), t)
	m.tip(Rect2(oc - Vector2(44, 44), Vector2(88, 88)), "Energy. Cards cost the Energy shown in their gem. Refills each turn.")
	_pile(draw_pile_c(), b.draw_pile.size(), "Draw", Color("7aa8ff"), "Draw pile (shown sorted)", b.draw_pile)
	_pile(discard_c(), b.discard.size(), "Discard", Color("ff8a6a"), "Discard pile", b.discard)
	if not b.exhaust.is_empty():
		A.text_c(m, discard_c() + Vector2(0, -64), "Exhausted %d" % b.exhaust.size(), 13, Color(0.8, 0.7, 0.9), 2)
	var my_turn: bool = b.phase == "player" and not b.over
	var er := end_rect()
	var pulse := my_turn and not _any_playable()
	if pulse:
		A.glow_circle(m, er.get_center(), 90 + sin(t * 5) * 8, Color("ffcf4a"), 4)
	m.button(er, "End Turn" if my_turn else "Enemy turn", end_turn, Color("ffb84a"), my_turn, 22)
	# hand
	var ht := hand_targets()
	var sb := int(p["st"].get("str", 0))
	var sap := int(p["st"].get("sapped", 0)) > 0
	var order: Array = range(b.hand.size())
	var top := selected if selected >= 0 else hover_card
	if not drag.is_empty():
		top = drag["hi"]
	if top >= 0 and top < b.hand.size():
		order.erase(top)
		order.append(top)
	for i in order:
		var cd: Dictionary = b.hand[i]
		var uid: int = cd["uid"]
		var cc: Vector2 = cpos.get(uid, ht[i]["c"])
		var rot: float = ht[i]["rot"]
		var sc := 1.0
		var is_drag: bool = not drag.is_empty() and drag["hi"] == i and drag["moved"]
		if is_drag:
			if targeted(i) and drag["pos"].y < hand_y() - 10:
				cc = Vector2(ht[i]["c"].x, hand_y() - 40)
			else:
				cc = drag["pos"]
			rot = 0.0
			sc = 1.08
		elif i == top and (i == selected or i == hover_card):
			rot = 0.0
			sc = 1.22 if not m.portrait else 1.3
			cc.y = minf(cc.y, H - CS.y * sc / 2 - 6)
			cc.x = clampf(cc.x, CS.x * sc / 2 + 6, W - CS.x * sc / 2 - 6)
		var ok := my_turn and playable(i)
		m.draw_set_transform(m.shake_off + cc, rot, Vector2(sc, sc))
		if ok and drag.is_empty():
			A.panel(m, Rect2(-CS / 2 - Vector2(4, 4), CS + Vector2(8, 8)), Color(0.4, 1, 0.6, 0.12 + 0.08 * sin(t * 4)), Color(0.5, 1, 0.6, 0.6), 14, 2)
		A.card(m, -CS / 2, cd["id"], cd["up"], t, CS, ok, sb, sap, i == selected)
		m.draw_set_transform(m.shake_off)
	# targeting arrow
	var src := -1
	var to := Vector2.ZERO
	if not drag.is_empty() and drag["moved"] and targeted(drag["hi"]) and drag["pos"].y < hand_y() - 10:
		src = drag["hi"]
		to = drag["pos"]
	if src >= 0:
		var from := Vector2(ht[src]["c"].x, hand_y() - 130)
		var ctrl := Vector2(from.x, to.y)
		var pts := PackedVector2Array()
		for j in 21:
			var q := j / 20.0
			pts.append(from.lerp(ctrl, q).lerp(ctrl.lerp(to, q), q))
		m.draw_polyline(pts, Color("ff7a5a"), 7, true)
		m.draw_polyline(pts, Color("ffd0a0"), 3, true)
		var dir := (pts[20] - pts[18]).normalized()
		m.draw_colored_polygon(PackedVector2Array([to + dir * 12, to - dir * 10 + dir.orthogonal() * 12, to - dir * 10 - dir.orthogonal() * 12]), Color("ffd0a0"))
	# flying played cards
	for fl in flying:
		var q: float = fl["t"]
		var pos: Vector2 = fl["from"].lerp(fl["to"], 1.0 - pow(1.0 - q, 3))
		m.draw_set_transform(m.shake_off + pos, q * 0.6, Vector2.ONE * (1.0 - q * 0.7))
		A.card(m, -CS / 2, fl["id"], fl["up"], t, CS)
		m.draw_set_transform(m.shake_off)
	# hint
	if my_turn and b.turn == 1 and m.meta["runs"] == 0 and m.run.floor_n <= 1 and drag.is_empty():
		A.text_c(m, Vector2(W / 2, hand_y() - (24 if not m.portrait else 120)), "Drag a card onto an enemy to play it  -  or tap a card, then tap a target" if not m.portrait else "Drag a card up to play it, or tap card then target", 17, Color("ffe9b8", 0.6 + 0.4 * sin(t * 3)), 3)
	if turn_t > 0:
		var a := minf(1.0, turn_t * 2.5)
		A.text_c(m, Vector2(W / 2, (H * 0.3) if not m.portrait else hud_h() + 40), turn_text, 40, Color(1, 0.92, 0.7, a), 5)
	m.hud()


func _any_playable() -> bool:
	for i in b.hand.size():
		if playable(i):
			return true
	return false


func _pile(c: Vector2, n: int, label: String, col: Color, title: String, list: Array) -> void:
	A.card_back(m, c - Vector2(22, 30), Vector2(44, 60), col)
	m.draw_circle(c + Vector2(18, 22), 15, Color(0.05, 0.03, 0.1))
	A.text_c(m, c + Vector2(18, 22), str(n), 16, Color.WHITE)
	A.text_c(m, c + Vector2(0, 44), label, 13, Color(0.85, 0.8, 0.9), 2)
	var r := Rect2(c - Vector2(30, 34), Vector2(60, 86))
	m.tip(r, "%s: %d card(s). Tap to view." % [label, n])
	var lst: Array = []
	for cd in list:
		lst.append({"id": cd["id"], "up": cd["up"]})
	m.hot(r, func(): m.open_cards(title, lst, "view"))
