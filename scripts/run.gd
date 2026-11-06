extends RefCounted
## Arcane Deck - one run: hero, deck, relics, gold, the branching map of
## each act, rewards, shops, rest sites and events.

const C := preload("res://scripts/cards.gd")
const D := preload("res://scripts/data.gd")
const ROWS := 10          # rows 0..9, then the boss
const COLS := 7

var hero := 0
var hp := 70
var max_hp := 70
var gold := 99
var deck: Array = []
var relics: Array = []
var act := 0
var map: Array = []       # [row][col] -> null or {"type", "next": [cols]}
var pos := Vector2i(-1, -1)
var at_boss := false
var floor_n := 0
var fights_this_act := 0
var stats := {"kills": 0, "elites": 0, "bosses": 0, "cards": 0, "dmg": 0, "gold": 0}
var rng := RandomNumberGenerator.new()
var seed_v := 0
var removal_cost := 75
var phoenix_used := false
var unlocked := 0
var won := false
var dead := false
var uid_next := 1
var seen_events: Array = []
var shop: Dictionary = {}


func start(h: int, seed_in: int, unlock_level: int) -> void:
	hero = h
	seed_v = seed_in
	rng.seed = seed_in
	unlocked = unlock_level
	var hd: Dictionary = C.HEROES[h]
	max_hp = hd["hp"]
	hp = max_hp
	for id in hd["deck"]:
		add_card(id)
	relics = [hd["relic"]]
	_gen_map()


func add_card(id: String, up := false) -> void:
	deck.append({"id": id, "up": up, "uid": uid_next})
	uid_next += 1


func add_relic(id: String) -> void:
	if relics.has(id):
		return
	relics.append(id)
	if id == "vigor_root":
		max_hp += 10
		hp += 10
	if id == "crown_of_ash":
		max_hp = maxi(10, max_hp - 8)
		hp = mini(hp, max_hp)


# ------------------------------------------------------------ map

func _gen_map() -> void:
	map = []
	for r in ROWS:
		var row: Array = []
		row.resize(COLS)
		map.append(row)
	var starts: Array = []
	for k in 6:
		var c := rng.randi_range(0, COLS - 1)
		if k == 1:
			while starts.has(c):
				c = rng.randi_range(0, COLS - 1)
		starts.append(c)
		_node(0, c)
		for r in ROWS - 1:
			var nc := clampi(c + rng.randi_range(-1, 1), 0, COLS - 1)
			# never cross an existing edge
			if nc != c and map[r][nc] != null and (map[r][nc]["next"] as Array).has(c):
				nc = c
			_node(r + 1, nc)
			if not (map[r][c]["next"] as Array).has(nc):
				map[r][c]["next"].append(nc)
			c = nc
	# node types
	var parents := {}
	for r in ROWS - 1:
		for c in COLS:
			if map[r][c] == null:
				continue
			for nc in map[r][c]["next"]:
				var k := Vector2i(r + 1, nc)
				if not parents.has(k):
					parents[k] = []
				parents[k].append(c)
	for r in ROWS:
		for c in COLS:
			if map[r][c] == null:
				continue
			var t := "fight"
			if r == 0:
				t = "fight"
			elif r == 5:
				t = "treasure"
			elif r == ROWS - 1:
				t = "rest"
			else:
				for tries in 6:
					t = _roll_type(r)
					var clash := false
					for pc in parents.get(Vector2i(r, c), []):
						if t in ["rest", "shop", "elite"] and map[r - 1][pc]["type"] == t:
							clash = true
					if not clash:
						break
			map[r][c]["type"] = t


func _node(r: int, c: int) -> void:
	if map[r][c] == null:
		map[r][c] = {"type": "fight", "next": []}


func _roll_type(r: int) -> String:
	var w := {"fight": 46, "event": 22}
	if r >= 4:
		w["elite"] = 11
	if r >= 4 and r != ROWS - 2:
		w["rest"] = 11
	if r >= 2:
		w["shop"] = 8
	var tot := 0
	for k in w:
		tot += w[k]
	var x := rng.randi_range(1, tot)
	for k in w:
		x -= w[k]
		if x <= 0:
			return k
	return "fight"


func available() -> Array:
	var out: Array = []
	if at_boss:
		return out
	if pos.x < 0:
		for c in COLS:
			if map[0][c] != null:
				out.append(Vector2i(0, c))
	elif pos.x == ROWS - 1:
		out.append(Vector2i(ROWS, 3))
	else:
		for nc in map[pos.x][pos.y]["next"]:
			out.append(Vector2i(pos.x + 1, nc))
	return out


## Move onto a node; returns its type.
func enter(v: Vector2i) -> String:
	floor_n += 1
	if v.x >= ROWS:
		at_boss = true
		return "boss"
	pos = v
	return map[v.x][v.y]["type"]


func node_type(v: Vector2i) -> String:
	if v.x >= ROWS:
		return "boss"
	return map[v.x][v.y]["type"]


func encounter(kind: String) -> Array:
	var enc: Dictionary = D.ENCOUNTERS[act]
	if kind == "boss":
		return enc["boss"].duplicate()
	if kind == "elite":
		var el: Array = enc["elite"]
		return el[rng.randi_range(0, el.size() - 1)].duplicate()
	var pool: Array = enc["easy"] if fights_this_act < 2 else enc["normal"]
	fights_this_act += 1
	return pool[rng.randi_range(0, pool.size() - 1)].duplicate()


func next_act() -> void:
	act += 1
	pos = Vector2i(-1, -1)
	at_boss = false
	fights_this_act = 0
	hp = mini(max_hp, hp + int((max_hp - hp) * 0.6))
	_gen_map()


# ------------------------------------------------------------ rewards

func _rarity(kind: String) -> int:
	var x := rng.randf()
	if kind == "boss":
		return 3
	if kind == "elite":
		return 3 if x < 0.12 else (2 if x < 0.55 else 1)
	return 3 if x < 0.04 + act * 0.02 else (2 if x < 0.36 else 1)


func card_choices(kind: String, n := 3) -> Array:
	var out: Array = []
	var guard := 0
	while out.size() < n and guard < 60:
		guard += 1
		var pl := C.pool(hero, _rarity(kind), unlocked)
		if pl.is_empty():
			continue
		var id: String = pl[rng.randi_range(0, pl.size() - 1)]
		if not out.has(id):
			out.append(id)
	return out


func gold_reward(kind: String) -> int:
	var g := rng.randi_range(12, 20) + act * 5
	if kind == "elite":
		g = rng.randi_range(30, 40) + act * 8
	elif kind == "boss":
		g = 90 + act * 15
	if relics.has("lucky_coin"):
		g = int(g * 1.25)
	return g


func gain_gold(g: int) -> void:
	gold += g
	if g > 0:
		stats["gold"] += g


func random_relic(tier := -1) -> String:
	var opts: Array = []
	for id in D.RELICS:
		var t: int = D.RELICS[id]["tier"]
		if relics.has(id) or t == 0 or t == 3:
			continue
		if tier >= 0 and t != tier:
			continue
		opts.append(id)
	if opts.is_empty():
		return ""
	return opts[rng.randi_range(0, opts.size() - 1)]


func boss_relic_choices() -> Array:
	var opts: Array = []
	for id in D.RELICS:
		if D.RELICS[id]["tier"] == 3 and not relics.has(id):
			opts.append(id)
	var out: Array = []
	while out.size() < 3 and not opts.is_empty():
		out.append(opts.pop_at(rng.randi_range(0, opts.size() - 1)))
	return out


# ------------------------------------------------------------ shop, rest

func price_mult() -> float:
	return 0.8 if relics.has("merchant_seal") else 1.0


func make_shop() -> void:
	var cards: Array = []
	for r in [1, 1, 2, 2, 3]:
		var pl := C.pool(hero, r, unlocked)
		for tries in 10:
			var id: String = pl[rng.randi_range(0, pl.size() - 1)]
			var dup := false
			for it in cards:
				if it["id"] == id:
					dup = true
			if not dup:
				var base: int = [0, 50, 75, 150][r]
				cards.append({"id": id, "price": int((base + rng.randi_range(-6, 10)) * price_mult()), "sold": false})
				break
	var rel: Array = []
	for t in [1, 2]:
		var id := random_relic(t)
		if id != "" and not rel.any(func(x): return x["id"] == id):
			rel.append({"id": id, "price": int((150 if t == 1 else 220) * price_mult() + rng.randi_range(-10, 10)), "sold": false})
	shop = {"cards": cards, "relics": rel, "removed": false}


func removal_price() -> int:
	return int(removal_cost * price_mult())


func buy_card(i: int) -> bool:
	var it: Dictionary = shop["cards"][i]
	if it["sold"] or gold < it["price"]:
		return false
	gold -= it["price"]
	it["sold"] = true
	add_card(it["id"])
	return true


func buy_relic(i: int) -> bool:
	var it: Dictionary = shop["relics"][i]
	if it["sold"] or gold < it["price"]:
		return false
	gold -= it["price"]
	it["sold"] = true
	add_relic(it["id"])
	return true


func remove_card(deck_i: int) -> void:
	if deck_i >= 0 and deck_i < deck.size():
		deck.remove_at(deck_i)


func rest_amount() -> int:
	var f := 0.3 + (0.15 if relics.has("hearth_stone") else 0.0)
	return int(max_hp * f)


func upgradable() -> Array:
	var out: Array = []
	for i in deck.size():
		var c := C.card(deck[i]["id"])
		if not deck[i]["up"] and c["t"] != 3:
			out.append(i)
	return out


# ------------------------------------------------------------ events

func pick_event() -> int:
	var opts: Array = []
	for i in D.EVENTS.size():
		if not seen_events.has(i):
			opts.append(i)
	if opts.is_empty():
		seen_events.clear()
		opts = range(D.EVENTS.size())
	var e: int = opts[rng.randi_range(0, opts.size() - 1)]
	seen_events.append(e)
	return e


## Apply an event choice. Returns a follow-up: "" , "fight", "card_choice:<ids>".
func event_choose(ev: int, ci: int) -> String:
	var ch: Dictionary = D.EVENTS[ev]["ch"][ci]
	if gold < int(ch.get("need", 0)):
		return "nogold"
	var follow := ""
	for op in ch["fx"]:
		match op[0]:
			"heal":
				hp = mini(max_hp, hp + op[1])
			"hp":
				hp = maxi(1, hp + op[1])
			"maxhp":
				max_hp += op[1]
				hp += op[1]
			"gold":
				if op[1] > 0:
					gain_gold(op[1])
				else:
					gold += op[1]
			"card_rare":
				var pl := C.pool(hero, 3, unlocked)
				add_card(pl[rng.randi_range(0, pl.size() - 1)])
			"card_choice":
				follow = "card_choice"
			"upgrade_rand":
				var ups := upgradable()
				for k in op[1]:
					if ups.is_empty():
						break
					var i: int = ups.pop_at(rng.randi_range(0, ups.size() - 1))
					deck[i]["up"] = true
			"remove_starter":
				for i in deck.size():
					if C.card(deck[i]["id"])["r"] == 0:
						deck.remove_at(i)
						break
			"relic":
				var r := random_relic()
				if r != "":
					add_relic(r)
			"curse":
				add_card("doubt")
			"dup":
				var opts: Array = []
				for i in deck.size():
					if C.card(deck[i]["id"])["r"] in [1, 2, 3]:
						opts.append(i)
				if opts.is_empty():
					opts = range(deck.size())
				var src: Dictionary = deck[opts[rng.randi_range(0, opts.size() - 1)]]
				add_card(src["id"], src["up"])
			"fight":
				follow = "fight"
	return follow


# ------------------------------------------------------------ score + save

func score() -> int:
	return floor_n * 10 + int(stats["kills"]) * 3 + int(stats["elites"]) * 25 + int(stats["bosses"]) * 80 + (400 if won else 0)


func to_dict() -> Dictionary:
	var m: Array = []
	for row in map:
		var rr: Array = []
		for n in row:
			rr.append(n)
		m.append(rr)
	return {"hero": hero, "hp": hp, "max_hp": max_hp, "gold": gold, "deck": deck, "relics": relics, "act": act,
		"map": m, "pos": [pos.x, pos.y], "at_boss": at_boss, "floor_n": floor_n, "fights": fights_this_act,
		"stats": stats, "seed": seed_v, "rng_state": str(rng.state), "removal_cost": removal_cost,
		"phoenix": phoenix_used, "unlocked": unlocked, "uid": uid_next, "seen": seen_events}


func from_dict(d: Dictionary) -> void:
	hero = int(d["hero"])
	hp = int(d["hp"])
	max_hp = int(d["max_hp"])
	gold = int(d["gold"])
	deck = []
	for cd in d["deck"]:
		deck.append({"id": str(cd["id"]), "up": bool(cd["up"]), "uid": int(cd["uid"])})
	relics = []
	for r in d["relics"]:
		relics.append(str(r))
	act = int(d["act"])
	map = []
	for row in d["map"]:
		var rr: Array = []
		for n in row:
			if n == null:
				rr.append(null)
			else:
				var nx: Array = []
				for c in n["next"]:
					nx.append(int(c))
				rr.append({"type": str(n["type"]), "next": nx})
		map.append(rr)
	pos = Vector2i(int(d["pos"][0]), int(d["pos"][1]))
	at_boss = bool(d.get("at_boss", false))
	floor_n = int(d["floor_n"])
	fights_this_act = int(d.get("fights", 0))
	for k in stats:
		stats[k] = int(d["stats"].get(k, 0))
	seed_v = int(d["seed"])
	rng.seed = seed_v
	rng.state = int(str(d.get("rng_state", "0")))
	removal_cost = int(d.get("removal_cost", 75))
	phoenix_used = bool(d.get("phoenix", false))
	unlocked = int(d.get("unlocked", 0))
	uid_next = int(d.get("uid", 200))
	seen_events = []
	for e in d.get("seen", []):
		seen_events.append(int(e))
