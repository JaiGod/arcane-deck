extends RefCounted
## Arcane Deck - combat rules. Pure logic: the view reads state and the
## `events` list, and drives the enemy phase one enemy at a time.

const C := preload("res://scripts/cards.gd")
const D := preload("res://scripts/data.gd")
const HAND_MAX := 10

var run
var p := {}
var enemies: Array = []
var draw_pile: Array = []
var hand: Array = []
var discard: Array = []
var exhaust: Array = []
var turn := 0
var phase := "player"
var events: Array = []
var rng := RandomNumberGenerator.new()
var over := false
var result := ""
var attacks_played := 0
var cards_this_turn := 0
var uid_next := 50000
var kills := 0
var dmg_dealt := 0
var cards_played := 0


func setup(r, enemy_ids: Array, seed_v: int) -> void:
	run = r
	rng.seed = seed_v
	p = {"hp": r.hp, "max_hp": r.max_hp, "block": 0, "energy": 0, "st": {}, "pw": {}}
	for cd in r.deck:
		draw_pile.append({"id": cd["id"], "up": cd["up"], "uid": cd["uid"]})
	if has_relic("sun_engine"):
		draw_pile.append(_token("doubt"))
	_shuffle(draw_pile)
	for id in enemy_ids:
		_spawn(id)
	start_turn()


func has_relic(id: String) -> bool:
	return run != null and run.relics.has(id)


func _token(id: String) -> Dictionary:
	uid_next += 1
	return {"id": id, "up": false, "uid": uid_next}


func _shuffle(a: Array) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = a[i]
		a[i] = a[j]
		a[j] = t


func _spawn(id: String) -> int:
	var e: Dictionary = D.ENEMIES[id]
	uid_next += 1
	var hp := rng.randi_range(e["hp"][0], e["hp"][1])
	var en := {"id": id, "n": e["n"], "hp": hp, "max_hp": hp, "block": 0, "st": {}, "hist": [], "pi": 0,
		"intent": {}, "alive": true, "uid": uid_next}
	enemies.append(en)
	_choose_intent(en)
	return enemies.size() - 1


func alive_enemies() -> Array:
	var out: Array = []
	for i in enemies.size():
		if enemies[i]["alive"]:
			out.append(i)
	return out


# ------------------------------------------------------------ turns

func start_turn() -> void:
	turn += 1
	phase = "player"
	cards_this_turn = 0
	if not p["pw"].has("fortress"):
		p["block"] = 0
	if turn == 1:
		_combat_start_relics()
	var poison := int(p["st"].get("poison", 0))
	if poison > 0:
		_player_lose(poison, "poison")
		_dec(p, "poison")
		if over:
			return
	var en := 3 + int(p["pw"].get("font", 0))
	for rid in ["sun_engine", "crown_of_ash"]:
		if has_relic(rid):
			en += 1
	if turn == 1 and has_relic("orrery_shard"):
		en += 1
	if turn % 3 == 0 and has_relic("pendulum"):
		en += 1
		events.append({"t": "relic", "id": "pendulum"})
	p["energy"] = en
	var pw: Dictionary = p["pw"]
	if pw.has("rage"):
		_add_st(p, "str", pw["rage"])
	if pw.has("rampart"):
		_gain_block(pw["rampart"])
	if pw.has("bloom"):
		for i in alive_enemies():
			apply(i, "poison", pw["bloom"])
	if pw.has("moteforge"):
		for k in pw["moteforge"]:
			_add_to_hand(_token("star_mote"))
	var n := 5 + int(pw.get("spark", 0))
	if has_relic("star_compass"):
		n += 1
	if turn == 1 and has_relic("feather_quill"):
		n += 2
	draw_cards(n)
	events.append({"t": "turn", "n": turn})


func _combat_start_relics() -> void:
	if has_relic("whetstone"):
		_add_st(p, "str", 1)
	if has_relic("bark_amulet"):
		_gain_block(7)
	if has_relic("thorn_ring"):
		_add_st(p, "spikes", 3)
	if has_relic("aegis_core"):
		_gain_block(14)
		_add_st(p, "agi", 1)
	for i in alive_enemies():
		if has_relic("seed_of_rot"):
			apply(i, "poison", 2)
		if has_relic("bone_dice"):
			apply(i, "vuln", 1)


func end_player_turn() -> void:
	if over or phase != "player":
		return
	if has_relic("ember_lamp") and p["energy"] > 0:
		_gain_block(p["energy"] * 3)
	if has_relic("mirror_veil") and p["block"] == 0:
		_gain_block(6)
		events.append({"t": "relic", "id": "mirror_veil"})
	var rg := int(p["st"].get("regen", 0))
	if rg > 0:
		heal(rg)
		_dec(p, "regen")
	_dec(p, "vuln")
	_dec(p, "sapped")
	for cd in hand:
		var c := C.card(cd["id"])
		if c["r"] == 4 and c["t"] == 0:
			exhaust.append(cd)
		else:
			discard.append(cd)
	hand.clear()
	phase = "enemy"


func enemy_act(i: int) -> void:
	if over or i >= enemies.size():
		return
	var e: Dictionary = enemies[i]
	if not e["alive"]:
		return
	e["block"] = 0
	var poison := int(e["st"].get("poison", 0))
	if poison > 0:
		_enemy_lose(i, poison, "poison")
		_dec(e, "poison")
		if not e["alive"]:
			return
	var mv: Dictionary = e["intent"]
	events.append({"t": "move", "who": i, "n": mv["n"], "atk": _is_attack(mv)})
	for op in mv["fx"]:
		if over or not e["alive"]:
			break
		match op[0]:
			"atk":
				var times: int = op[2] if op.size() > 2 else 1
				for k in times:
					if over or not e["alive"]:
						break
					_enemy_hit(i, op[1])
			"blk":
				e["block"] += op[1]
				events.append({"t": "block", "who": i, "amt": op[1]})
			"blk_all":
				for j in alive_enemies():
					enemies[j]["block"] += op[1]
			"buff":
				_add_st(e, op[1], op[2])
				events.append({"t": "status", "who": i, "st": op[1], "n": op[2]})
			"buff_all":
				for j in alive_enemies():
					_add_st(enemies[j], op[1], op[2])
					events.append({"t": "status", "who": j, "st": op[1], "n": op[2]})
			"debuff":
				_add_st(p, op[1], op[2])
				events.append({"t": "status", "who": -1, "st": op[1], "n": op[2]})
			"heal":
				e["hp"] = mini(e["max_hp"], e["hp"] + op[1])
				events.append({"t": "heal", "who": i, "amt": op[1]})
			"summon":
				if alive_enemies().size() < 5:
					var ni := _spawn(op[1])
					events.append({"t": "summon", "who": ni})
			"doubt":
				for k in op[1]:
					discard.append(_token("doubt"))
				events.append({"t": "doubt", "who": i, "n": op[1]})
	if e["alive"]:
		_dec(e, "vuln")
		_dec(e, "sapped")
		_choose_intent(e)


func end_enemy_phase() -> void:
	if not over:
		start_turn()


## Convenience for the bot / tests: the whole enemy phase at once.
func end_turn() -> void:
	end_player_turn()
	var n := enemies.size()
	for i in n:
		enemy_act(i)
		if over:
			return
	end_enemy_phase()


# ------------------------------------------------------------ playing cards

func can_play(hi: int, ti: int) -> String:
	if over or phase != "player":
		return "Wait for your turn"
	if hi < 0 or hi >= hand.size():
		return "No card"
	var cd: Dictionary = hand[hi]
	var cost := C.cost_of(cd["id"], cd["up"])
	if cost < 0:
		return "That card is unplayable"
	if cost > p["energy"]:
		return "Not enough energy"
	if C.needs_target(cd["id"]):
		if ti < 0 or ti >= enemies.size() or not enemies[ti]["alive"]:
			return "Choose a target"
	return ""


func play(hi: int, ti: int) -> String:
	var err := can_play(hi, ti)
	if err != "":
		return err
	var cd: Dictionary = hand[hi]
	var c := C.card(cd["id"])
	p["energy"] -= C.cost_of(cd["id"], cd["up"])
	hand.remove_at(hi)
	var times := 1
	if int(p["st"].get("echo", 0)) > 0:
		times += 1
		_dec(p, "echo")
	if cards_this_turn == 0 and p["pw"].has("orrery"):
		times += 1
	events.append({"t": "play", "uid": cd["uid"], "id": cd["id"], "target": ti, "times": times})
	var fx := C.fx_of(cd["id"], cd["up"])
	for k in times:
		if k > 0 and ti >= 0 and not enemies[ti]["alive"] and C.needs_target(cd["id"]):
			var al := alive_enemies()
			if al.is_empty():
				break
			ti = al[0]
		for op in fx:
			if over:
				break
			_do(op, ti)
	cards_this_turn += 1
	cards_played += 1
	if c["t"] == 0:
		attacks_played += 1
		if has_relic("storm_bell") and attacks_played % 3 == 0 and not over:
			events.append({"t": "relic", "id": "storm_bell"})
			for i in alive_enemies():
				attack(i, 5, false)
	if c["t"] == 2:
		pass
	elif c.get("x", false) or c["r"] == 4:
		exhaust.append(cd)
	else:
		discard.append(cd)
	return ""


func _do(op: Array, ti: int) -> void:
	var st: Dictionary = p["st"]
	match op[0]:
		"dmg":
			attack(ti, op[1], true)
		"dmg_all":
			for i in alive_enemies():
				attack(i, op[1], true)
		"multi":
			for k in op[2]:
				if ti >= 0 and enemies[ti]["alive"]:
					attack(ti, op[1], true)
		"multi_all":
			for k in op[2]:
				for i in alive_enemies():
					attack(i, op[1], true)
		"blk":
			_gain_block(op[1] + int(st.get("agi", 0)))
		"draw":
			draw_cards(op[1])
		"energy":
			p["energy"] += op[1]
			events.append({"t": "energy", "amt": op[1]})
		"apply":
			apply(ti, op[1], op[2])
		"apply_all":
			for i in alive_enemies():
				apply(i, op[1], op[2])
		"buff":
			_add_st(p, op[1], op[2])
			events.append({"t": "status", "who": -1, "st": op[1], "n": op[2]})
		"heal":
			heal(op[1])
		"lose_hp":
			_player_lose(op[1], "self")
		"dmg_blk":
			attack(ti, p["block"], false)
		"dmg_poison":
			attack(ti, int(enemies[ti]["st"].get("poison", 0)) * op[1], false)
		"poison_mult":
			var cur := int(enemies[ti]["st"].get("poison", 0))
			if cur > 0:
				enemies[ti]["st"]["poison"] = cur * op[1]
				events.append({"t": "status", "who": ti, "st": "poison", "n": cur * (op[1] - 1)})
		"dmg_hand":
			attack(ti, op[1] * hand.size(), false)
		"add_card":
			for k in op[2]:
				_add_to_hand(_token(op[1]))
		"power":
			p["pw"][op[1]] = int(p["pw"].get(op[1], 0)) + op[2]
			events.append({"t": "power", "id": op[1]})


func _add_to_hand(cd: Dictionary) -> void:
	if hand.size() < HAND_MAX:
		hand.append(cd)
	else:
		discard.append(cd)


func draw_cards(n: int) -> void:
	for k in n:
		if hand.size() >= HAND_MAX:
			return
		if draw_pile.is_empty():
			if discard.is_empty():
				return
			draw_pile = discard.duplicate()
			discard.clear()
			_shuffle(draw_pile)
			events.append({"t": "shuffle"})
		hand.append(draw_pile.pop_back())


# ------------------------------------------------------------ damage

func player_attack_value(base: int, use_str: bool) -> int:
	var v := base + (int(p["st"].get("str", 0)) if use_str else 0)
	if int(p["st"].get("sapped", 0)) > 0:
		v = int(floor(v * 0.75))
	return maxi(0, v)


func attack(ti: int, base: int, use_str: bool) -> void:
	if ti < 0 or ti >= enemies.size() or not enemies[ti]["alive"]:
		return
	var e: Dictionary = enemies[ti]
	var v := player_attack_value(base, use_str)
	if int(e["st"].get("vuln", 0)) > 0:
		v = int(floor(v * 1.5))
	_enemy_lose(ti, v, "hit")
	if p["pw"].has("envenom") and e["alive"]:
		apply(ti, "poison", p["pw"]["envenom"])
	var sp := int(e["st"].get("spikes", 0))
	if sp > 0 and e["alive"]:
		_player_lose(sp, "spikes")


## Damage to an enemy. kind "hit" goes through block, "poison" does not.
func _enemy_lose(ti: int, v: int, kind: String) -> void:
	var e: Dictionary = enemies[ti]
	var blocked := 0
	if kind == "hit":
		blocked = mini(e["block"], v)
		e["block"] -= blocked
		v -= blocked
	e["hp"] -= v
	dmg_dealt += v
	events.append({"t": "hit", "who": ti, "amt": v, "blocked": blocked, "kind": kind})
	if e["hp"] <= 0:
		e["hp"] = 0
		e["alive"] = false
		kills += 1
		events.append({"t": "die", "who": ti})
		if has_relic("leech_fang"):
			heal(3)
		if alive_enemies().is_empty():
			over = true
			result = "win"


func _enemy_hit(i: int, base: int) -> void:
	var e: Dictionary = enemies[i]
	var v := enemy_attack_value(e, base)
	var blocked := mini(p["block"], v)
	p["block"] -= blocked
	v -= blocked
	events.append({"t": "hit", "who": -1, "amt": v, "blocked": blocked, "kind": "hit", "src": i})
	_player_lose(v, "", false)
	var sp := int(p["st"].get("spikes", 0))
	if sp > 0 and not over:
		_enemy_lose(i, sp, "poison")


func enemy_attack_value(e: Dictionary, base: int) -> int:
	var v := base + int(e["st"].get("str", 0))
	if int(e["st"].get("sapped", 0)) > 0:
		v = int(floor(v * 0.75))
	if int(p["st"].get("vuln", 0)) > 0:
		v = int(floor(v * 1.5))
	return maxi(0, v)


func _player_lose(v: int, kind: String, log := true) -> void:
	if v <= 0:
		return
	p["hp"] -= v
	if log:
		events.append({"t": "hit", "who": -1, "amt": v, "blocked": 0, "kind": kind})
	if p["hp"] <= 0:
		if has_relic("phoenix_plume") and not run.phoenix_used:
			run.phoenix_used = true
			p["hp"] = int(p["max_hp"] * 0.4)
			events.append({"t": "relic", "id": "phoenix_plume"})
			return
		p["hp"] = 0
		over = true
		result = "lose"


func heal(n: int) -> void:
	var before: int = p["hp"]
	p["hp"] = mini(p["max_hp"], p["hp"] + n)
	if p["hp"] > before:
		events.append({"t": "heal", "who": -1, "amt": p["hp"] - before})


func _gain_block(n: int) -> void:
	if n <= 0:
		return
	p["block"] += n
	events.append({"t": "block", "who": -1, "amt": n})


func apply(ti: int, st: String, n: int) -> void:
	if ti < 0 or ti >= enemies.size() or not enemies[ti]["alive"]:
		return
	if st == "poison" and has_relic("hydra_scale"):
		n += 1
	_add_st(enemies[ti], st, n)
	events.append({"t": "status", "who": ti, "st": st, "n": n})


func _add_st(u: Dictionary, st: String, n: int) -> void:
	u["st"][st] = int(u["st"].get(st, 0)) + n


func _dec(u: Dictionary, st: String) -> void:
	var v := int(u["st"].get(st, 0))
	if v <= 1:
		u["st"].erase(st)
	else:
		u["st"][st] = v - 1


# ------------------------------------------------------------ intents

func _choose_intent(e: Dictionary) -> void:
	var def: Dictionary = D.ENEMIES[e["id"]]
	var moves: Array = def["moves"]
	var mi := 0
	if def.has("pat"):
		var pat: Array = def["pat"]
		mi = pat[e["pi"] % pat.size()]
		e["pi"] += 1
	else:
		var opts: Array = []
		var h: Array = e["hist"]
		for k in moves.size():
			if h.size() >= 2 and h[-1] == k and h[-2] == k:
				continue
			opts.append(k)
		mi = opts[rng.randi_range(0, opts.size() - 1)]
	e["hist"].append(mi)
	if e["hist"].size() > 4:
		e["hist"].pop_front()
	e["intent"] = moves[mi]


func _is_attack(mv: Dictionary) -> bool:
	for op in mv["fx"]:
		if op[0] == "atk":
			return true
	return false


## What the enemy will do next, for the intent icon: kinds + damage.
func intent_info(i: int) -> Dictionary:
	var e: Dictionary = enemies[i]
	var info := {"kinds": [], "dmg": 0, "times": 0, "name": e["intent"].get("n", "")}
	for op in e["intent"].get("fx", []):
		match op[0]:
			"atk":
				info["dmg"] = enemy_attack_value(e, op[1])
				info["times"] = op[2] if op.size() > 2 else 1
				if not info["kinds"].has("atk"):
					info["kinds"].append("atk")
			"blk", "blk_all":
				info["kinds"].append("def")
			"buff", "buff_all", "heal":
				if not info["kinds"].has("buff"):
					info["kinds"].append("buff")
			"debuff", "doubt":
				if not info["kinds"].has("debuff"):
					info["kinds"].append("debuff")
			"summon":
				if not info["kinds"].has("summon"):
					info["kinds"].append("summon")
	return info


func intent_text(i: int) -> String:
	var info := intent_info(i)
	var parts: PackedStringArray = []
	for k in info["kinds"]:
		match k:
			"atk":
				parts.append("attack for %d%s" % [info["dmg"], (" x%d" % info["times"]) if info["times"] > 1 else ""])
			"def":
				parts.append("defend")
			"buff":
				parts.append("empower itself")
			"debuff":
				parts.append("curse you")
			"summon":
				parts.append("call for help")
	return "%s: will %s." % [info["name"], " and ".join(parts)]
