extends Node
## Drives the real Main scene through every screen with its test hook.

var main
var fails := 0


func frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func cmd(c: String) -> Dictionary:
	var r: Dictionary = main.test_cmd(c)
	await frames(2)
	return r


func run_ui(_smoke) -> int:
	main = load("res://main.tscn").instantiate()
	add_child(main)
	await frames(5)
	main.clear_run_save()
	var seen := {}
	for run_i in 2:
		await cmd("new:%d" % run_i)
		var steps := 0
		while steps < 3000:
			steps += 1
			var s: String = main.screen
			seen[s] = true
			if s == "end":
				break
			match s:
				"map":
					if steps % 7 == 0:
						await cmd("deck")
						await cmd("overlay:")
						await cmd("overlay:pause")
						await cmd("overlay:")
					await cmd("node:" + ["rest", "shop", "event", "elite", "fight", "treasure"][steps % 6])
				"battle":
					seen["kind_" + main.bv.kind] = true
					if run_i == 1 and main.run.floor_n >= 4:
						await cmd("lose")
					else:
						await cmd("play")
						await cmd("win")
					if main.bv and main.bv.b.over:
						main.bv.end_t = 5.0
						await frames(3)
				"reward":
					await cmd("take" if steps % 2 == 0 else "skip")
				"bossrelic", "treasure":
					await cmd("take")
				"shop":
					main.scr._buy_card(0)
					main.scr._buy_relic(0)
					await frames(2)
					await cmd("go:map")
				"rest":
					if steps % 2 == 0:
						await cmd("rest")
					else:
						main.scr._smith()
						await frames(2)
						var cb: Callable = main.cards_ov["cb"]
						cb.call(main.cards_ov["list"][0]["i"])
						await frames(2)
				"event":
					if main.event_result != "":
						await cmd("go:map")
					else:
						var ch: Array = preload("res://scripts/data.gd").EVENTS[main.event_i]["ch"]
						await cmd("event:%d" % (ch.size() - 1 if steps % 3 else 0))
				_:
					await cmd("go:map")
		if main.screen != "end":
			fails += 1
			print("FAIL: ui run %d did not end (screen %s, floor %d)" % [run_i, main.screen, main.run.floor_n])
		else:
			print("  ui run %d ended: won=%s act %d floor %d score %d" % [run_i, main.run.won, main.run.act + 1, main.run.floor_n, main.run.score()])
		if run_i == 0 and not main.run.won:
			fails += 1
			print("FAIL: forced-win run should win")
	# shop and elite are random on the map, so visit them directly too
	await cmd("new:1")
	main.open_node("shop")
	await frames(2)
	if main.screen == "shop":
		seen["shop"] = true
		main.scr._buy_card(0)
	main.open_node("elite")
	await frames(2)
	if main.bv and main.bv.kind == "elite":
		seen["kind_elite"] = true
	await cmd("go:map")
	for s in ["title", "heroes", "history", "help"]:
		await cmd("go:" + s)
		await frames(3)
	print("  screens seen: ", seen.keys())
	for need in ["map", "battle", "reward", "shop", "rest", "event", "treasure", "bossrelic", "end", "kind_boss", "kind_elite"]:
		if not seen.has(need):
			fails += 1
			print("FAIL: never saw ", need)
	if main.meta["history"].size() < 2:
		fails += 1
		print("FAIL: history not recorded")
	return fails
