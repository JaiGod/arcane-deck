extends Node
## Headless smoke test: unit checks on the rules, a bot that plays full runs
## with every hero, then the real Main scene is driven through every screen.
## Prints "SMOKE OK" when everything passed.

const C := preload("res://scripts/cards.gd")
const D := preload("res://scripts/data.gd")
const Run := preload("res://scripts/run.gd")
const Battle := preload("res://scripts/battle.gd")
const Bot := preload("res://tests/bot.gd")
var fails := 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _ready() -> void:
	var t0 := Time.get_ticks_msec()
	# every hero has a 30-card pool; every card has text and a valid art
	for h in 3:
		check(C.hero_cards(h).size() == 30, "hero %d has 30 cards (%d)" % [h, C.hero_cards(h).size()])
		for id in C.HEROES[h]["deck"]:
			check(C.CARDS.has(id), "starter card " + id)
		check(D.RELICS.has(C.HEROES[h]["relic"]), "starter relic")
	for id in C.CARDS:
		var c: Dictionary = C.CARDS[id]
		check(C.text(id, false) != "" and C.text(id, true) != "", "text " + id)
		if c["t"] != 3:
			check(C.text(id, true) != C.text(id, false) or C.cost_of(id, true) < C.cost_of(id, false) or c["r"] == 4, "upgrade changes " + id)
	for id in D.ENEMIES:
		for mv in D.ENEMIES[id]["moves"]:
			for op in mv["fx"]:
				if op[0] == "summon":
					check(D.ENEMIES.has(op[1]), "summon id")
	# rules: block, vulnerable, poison, strength
	var r := Run.new()
	r.start(0, 7, 0)
	var b := Battle.new()
	b.setup(r, ["bog_lurker"], 3)
	b.enemies[0]["hp"] = 100
	b.enemies[0]["max_hp"] = 100
	b.hand.clear()
	b.hand.append({"id": "shield_bash", "up": false, "uid": 1})
	b.hand.append({"id": "hammer_blow", "up": false, "uid": 2})
	b.hand.append({"id": "iron_guard", "up": true, "uid": 3})
	b.p["energy"] = 10
	check(b.play(0, 0) == "", "play bash")
	check(b.enemies[0]["hp"] == 92 and b.enemies[0]["st"]["vuln"] == 2, "bash dmg + vuln")
	b.play(0, 0)
	check(b.enemies[0]["hp"] == 83, "vulnerable 1.5x (got %d)" % b.enemies[0]["hp"])
	b.play(0, -1)
	check(b.p["block"] == 8, "upgraded guard 8 block")
	check(b.can_play(0, 0) != "", "empty hand")
	b.enemies[0]["st"]["poison"] = 5
	b.enemies[0]["intent"] = {"n": "Test", "fx": [["atk", 10]]}
	var hp0: int = b.p["hp"]
	b.end_turn()
	check(b.enemies[0]["hp"] == 78, "poison ticks")
	check(b.p["hp"] == hp0 - 2, "block absorbs (hp %d)" % b.p["hp"])
	check(b.hand.size() == 5 and b.turn == 2, "drew new hand")
	# upgrades + save round-trip
	r.deck[0]["up"] = true
	var d: Dictionary = JSON.parse_string(JSON.stringify(r.to_dict()))
	var r2 := Run.new()
	r2.from_dict(d)
	check(r2.deck.size() == r.deck.size() and r2.deck[0]["up"] and r2.map.size() == Run.ROWS, "save round trip")
	check(r2.available().size() > 0, "map has starts")
	# bot plays runs with every hero
	var bot := Bot.new()
	var wins := 0
	var acts := [0, 0, 0]
	for h in 3:
		for s in 8:
			var rr = bot.play_run(h, 100 + s * 13 + h)
			acts[h] += rr.act + 1
			if rr.won:
				wins += 1
			print("  hero %d seed %d: %s act %d floor %d deck %d relics %d score %d" % [h, s, "WIN " if rr.won else "dead", rr.act + 1, rr.floor_n, rr.deck.size(), rr.relics.size(), rr.score()])
	for l in bot.log_lines:
		print(l)
	print("bot wins %d / 24, avg act per hero %s" % [wins, str(acts.map(func(a): return a / 8.0))])
	check(acts[0] + acts[1] + acts[2] > 24, "bot gets past act 1 sometimes")
	print("sim time: %d ms" % (Time.get_ticks_msec() - t0))
	if ResourceLoader.exists("res://tests/ui_test.gd"):
		var ui = load("res://tests/ui_test.gd").new()
		add_child(ui)
		fails += await ui.run_ui(self)
	if fails == 0:
		print("SMOKE OK")
	else:
		print("SMOKE FAILED: %d" % fails)
	get_tree().quit(0 if fails == 0 else 1)
