extends RefCounted
## A simple greedy bot that plays whole runs through the pure-logic layer.

const C := preload("res://scripts/cards.gd")
const D := preload("res://scripts/data.gd")
const Run := preload("res://scripts/run.gd")
const Battle := preload("res://scripts/battle.gd")

var log_lines: Array = []


func incoming(b) -> int:
	var t := 0
	for i in b.alive_enemies():
		var inf: Dictionary = b.intent_info(i)
		if inf["kinds"].has("atk"):
			t += inf["dmg"] * inf["times"]
	return t


func card_score(b, cd: Dictionary) -> float:
	var c := C.card(cd["id"])
	if c["t"] == 3:
		return -1
	var s := 1.0
	var need: int = incoming(b) - b.p["block"]
	for op in C.fx_of(cd["id"], cd["up"]):
		match op[0]:
			"power":
				s += 80
			"blk":
				s += (op[1] * 2.2 if need > 0 else op[1] * 0.3)
			"dmg", "dmg_all":
				s += op[1] * (1.6 if op[0] == "dmg_all" and b.alive_enemies().size() > 1 else 1.0)
			"multi", "multi_all":
				s += op[1] * op[2]
			"apply", "apply_all":
				s += op[2] * 1.5
			"buff":
				s += op[2] * 6
			"draw":
				s += op[1] * 5
			"energy":
				s += op[1] * 9
			"dmg_blk":
				s += b.p["block"]
			"dmg_poison", "poison_mult":
				s += 4
			"add_card", "heal":
				s += 4
			"dmg_hand":
				s += op[1] * b.hand.size()
	if c["t"] == 2:
		s += 60
	return s / maxf(0.6, C.cost_of(cd["id"], cd["up"]))


func play_battle(r, ids: Array, seed_v: int):
	var b := Battle.new()
	b.setup(r, ids, seed_v)
	var guard := 0
	while not b.over and guard < 400:
		guard += 1
		var plays := 0
		while not b.over and plays < 30:
			plays += 1
			var best := -1
			var bs := 0.0
			for i in b.hand.size():
				var tgt := _target(b)
				if b.can_play(i, tgt) != "":
					continue
				var sc := card_score(b, b.hand[i])
				if sc > bs:
					bs = sc
					best = i
			if best < 0:
				break
			b.play(best, _target(b))
			b.events.clear()
		if b.over:
			break
		b.end_turn()
		b.events.clear()
	r.hp = b.p["hp"]
	r.stats["kills"] += b.kills
	return b


func _target(b) -> int:
	var best := -1
	var hp := 99999
	for i in b.alive_enemies():
		if b.enemies[i]["hp"] < hp:
			hp = b.enemies[i]["hp"]
			best = i
	return best


func after_win(r, kind: String) -> void:
	r.gain_gold(r.gold_reward(kind))
	if r.relics.has("ember_heart"):
		r.hp = mini(r.max_hp, r.hp + 6)
	var ch: Array = r.card_choices(kind)
	if not ch.is_empty() and r.deck.size() < 26:
		r.add_card(ch[0])
	if kind == "elite":
		r.stats["elites"] += 1
		var rel: String = r.random_relic()
		if rel != "":
			r.add_relic(rel)


## Plays a whole run. Returns the Run.
func play_run(hero: int, seed_v: int, unlocked := 4):
	var r := Run.new()
	r.start(hero, seed_v, unlocked)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v * 7 + 1
	var steps := 0
	while not r.won and not r.dead and steps < 200:
		steps += 1
		var av: Array = r.available()
		var pick: Vector2i = av[0]
		var best := -999.0
		for v in av:
			var t: String = r.node_type(v)
			var sc := rng.randf() * 3.0
			var frac := float(r.hp) / r.max_hp
			match t:
				"rest": sc += 8 if frac < 0.55 else 1
				"elite": sc += 6 if frac > 0.75 else -6
				"shop": sc += 4 if r.gold > 120 else 0
				"event": sc += 3
				"treasure": sc += 9
				"fight": sc += 2
			if sc > best:
				best = sc
				pick = v
		var t: String = r.enter(pick)
		match t:
			"fight", "elite", "boss":
				var b = play_battle(r, r.encounter(t), seed_v + steps)
				if b.result != "win":
					r.dead = true
					log_lines.append("  died act %d floor %d vs %s" % [r.act + 1, r.floor_n, str(b.enemies.map(func(e): return e["id"]))])
					break
				after_win(r, t)
				if t == "boss":
					r.stats["bosses"] += 1
					if r.act == 2:
						r.won = true
					else:
						var br: Array = r.boss_relic_choices()
						if not br.is_empty():
							r.add_relic(br[0])
						r.next_act()
			"rest":
				if r.hp < r.max_hp * 0.6 or r.upgradable().is_empty():
					r.hp = mini(r.max_hp, r.hp + r.rest_amount())
				else:
					var u: Array = r.upgradable()
					r.deck[u[u.size() - 1]]["up"] = true
			"shop":
				r.make_shop()
				if r.gold >= r.removal_price():
					for i in r.deck.size():
						if C.card(r.deck[i]["id"])["r"] == 0 or r.deck[i]["id"] == "doubt":
							r.gold -= r.removal_price()
							r.remove_card(i)
							r.removal_cost += 25
							break
				for i in r.shop["relics"].size():
					r.buy_relic(i)
				for i in r.shop["cards"].size():
					r.buy_card(i)
			"treasure":
				var rel: String = r.random_relic()
				if rel != "":
					r.add_relic(rel)
			"event":
				var ev: int = r.pick_event()
				var ci := 0
				if int(D.EVENTS[ev]["ch"][0].get("need", 0)) > r.gold:
					ci = 1
				var f: String = r.event_choose(ev, ci)
				if f == "fight":
					var b2 = play_battle(r, r.encounter("elite"), seed_v + 999 + steps)
					if b2.result != "win":
						r.dead = true
						break
					after_win(r, "elite")
				elif f == "card_choice":
					var ch: Array = r.card_choices("fight")
					if not ch.is_empty():
						r.add_card(ch[0])
	return r
