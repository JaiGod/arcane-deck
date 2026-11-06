extends RefCounted
## Arcane Deck - heroes and their 30-card pools (plus tokens and curses).
## Card keys: n name, h hero (-1 = none), r rarity (0 starter, 1 common,
## 2 uncommon, 3 rare, 4 special), t type (0 attack, 1 skill, 2 power,
## 3 curse), c cost, fx effect ops, art motif, x exhaust, lock unlock order,
## u upgraded fx override, uc upgraded cost.

const HEROES := [
	{"id": "brakka", "name": "Brakka", "title": "the Ironwarden", "hp": 80, "relic": "ember_heart",
		"col": Color("ff7a3d"), "col2": Color("7a2a1a"), "glow": Color("ffc36b"),
		"blurb": "A forge-born knight. Stacks Block, grows Strength and turns armor into hammer blows.",
		"deck": ["hammer_blow", "hammer_blow", "hammer_blow", "hammer_blow", "hammer_blow", "iron_guard", "iron_guard", "iron_guard", "iron_guard", "shield_bash"]},
	{"id": "nyx", "name": "Nyx", "title": "the Thornwitch", "hp": 70, "relic": "seed_of_rot",
		"col": Color("7be36a"), "col2": Color("2d1f4f"), "glow": Color("d2ff8a"),
		"blurb": "A swamp witch who wins slowly and surely. Poison, Agility and endless thorns.",
		"deck": ["thorn_lash", "thorn_lash", "thorn_lash", "thorn_lash", "thorn_lash", "bark_skin", "bark_skin", "bark_skin", "bark_skin", "venom_dart"]},
	{"id": "orrin", "name": "Orrin", "title": "the Starweaver", "hp": 66, "relic": "orrery_shard",
		"col": Color("7aa8ff"), "col2": Color("1a1d4a"), "glow": Color("ffe27a"),
		"blurb": "An astral sage. Draws deep, conjures Star Motes and casts spells twice.",
		"deck": ["star_bolt", "star_bolt", "star_bolt", "star_bolt", "star_bolt", "aether_ward", "aether_ward", "aether_ward", "aether_ward", "comet_shard"]},
]

const CARDS := {
	# ------------------------------------------------ Brakka, the Ironwarden
	"hammer_blow": {"n": "Hammer Blow", "h": 0, "r": 0, "t": 0, "c": 1, "fx": [["dmg", 6]], "art": "fist"},
	"iron_guard": {"n": "Iron Guard", "h": 0, "r": 0, "t": 1, "c": 1, "fx": [["blk", 5]], "art": "shield"},
	"shield_bash": {"n": "Shield Bash", "h": 0, "r": 0, "t": 0, "c": 2, "fx": [["dmg", 8], ["apply", "vuln", 2]], "art": "burst"},
	"cleave_arc": {"n": "Cleave Arc", "h": 0, "r": 1, "t": 0, "c": 1, "fx": [["dmg_all", 8]], "art": "blade"},
	"twin_swing": {"n": "Twin Swing", "h": 0, "r": 1, "t": 0, "c": 1, "fx": [["multi", 5, 2]], "art": "blade"},
	"brace": {"n": "Brace", "h": 0, "r": 1, "t": 1, "c": 1, "fx": [["blk", 6], ["draw", 1]], "art": "shield"},
	"heave": {"n": "Heave", "h": 0, "r": 1, "t": 0, "c": 2, "fx": [["dmg", 14]], "art": "mountain"},
	"rivet_strike": {"n": "Rivet Strike", "h": 0, "r": 1, "t": 0, "c": 1, "fx": [["dmg", 7], ["blk", 4]], "art": "gear"},
	"bulwark_slam": {"n": "Bulwark Slam", "h": 0, "r": 1, "t": 0, "c": 1, "fx": [["dmg_blk"]], "art": "shield", "uc": 0},
	"sunder": {"n": "Sunder", "h": 0, "r": 1, "t": 0, "c": 1, "fx": [["dmg", 6], ["apply", "sapped", 2]], "art": "fang"},
	"plate_up": {"n": "Plate Up", "h": 0, "r": 1, "t": 1, "c": 1, "fx": [["blk", 8]], "art": "shield"},
	"stoke": {"n": "Stoke", "h": 0, "r": 1, "t": 1, "c": 0, "fx": [["blk", 3], ["draw", 1]], "art": "flame"},
	"grit": {"n": "Grit", "h": 0, "r": 1, "t": 1, "c": 1, "fx": [["blk", 5], ["buff", "spikes", 2]], "art": "fang"},
	"quake": {"n": "Quake", "h": 0, "r": 1, "t": 0, "c": 2, "fx": [["dmg_all", 7], ["apply_all", "sapped", 1]], "art": "mountain"},
	"reckless_charge": {"n": "Reckless Charge", "h": 0, "r": 1, "t": 0, "c": 0, "fx": [["dmg", 9], ["lose_hp", 3]], "art": "comet"},
	"battle_hymn": {"n": "Battle Hymn", "h": 0, "r": 2, "t": 1, "c": 1, "fx": [["buff", "str", 2]], "art": "crown", "x": true},
	"fortress": {"n": "Fortress", "h": 0, "r": 2, "t": 2, "c": 2, "fx": [["power", "fortress", 1]], "art": "mountain", "uc": 1, "lock": 1},
	"ember_rage": {"n": "Ember Rage", "h": 0, "r": 2, "t": 2, "c": 1, "fx": [["power", "rage", 1]], "art": "flame"},
	"iron_wall": {"n": "Iron Wall", "h": 0, "r": 2, "t": 1, "c": 2, "fx": [["blk", 16]], "art": "shield"},
	"tremor_strike": {"n": "Tremor Strike", "h": 0, "r": 2, "t": 0, "c": 2, "fx": [["dmg_all", 10], ["apply_all", "vuln", 1]], "art": "burst"},
	"bastion_crash": {"n": "Bastion Crash", "h": 0, "r": 2, "t": 0, "c": 2, "fx": [["blk", 7], ["dmg_blk"]], "art": "shield"},
	"rampart": {"n": "Rampart", "h": 0, "r": 2, "t": 2, "c": 1, "fx": [["power", "rampart", 4]], "art": "gear"},
	"bloodforge": {"n": "Bloodforge", "h": 0, "r": 2, "t": 1, "c": 0, "fx": [["lose_hp", 4], ["energy", 2]], "art": "heart", "x": true, "u": [["lose_hp", 3], ["energy", 2], ["draw", 1]]},
	"spiked_mail": {"n": "Spiked Mail", "h": 0, "r": 2, "t": 2, "c": 1, "fx": [["buff", "spikes", 3]], "art": "fang"},
	"iron_cyclone": {"n": "Iron Cyclone", "h": 0, "r": 2, "t": 0, "c": 2, "fx": [["multi_all", 5, 2]], "art": "cyclone", "lock": 2},
	"titan_grip": {"n": "Titan Grip", "h": 0, "r": 3, "t": 0, "c": 3, "fx": [["dmg", 30], ["apply", "vuln", 2]], "art": "fist"},
	"unbreakable": {"n": "Unbreakable", "h": 0, "r": 3, "t": 1, "c": 2, "fx": [["blk", 30]], "art": "mountain", "x": true, "lock": 3},
	"molten_core": {"n": "Molten Core", "h": 0, "r": 3, "t": 2, "c": 2, "fx": [["power", "rage", 2]], "art": "orb", "lock": 4},
	"avalanche": {"n": "Avalanche", "h": 0, "r": 3, "t": 0, "c": 2, "fx": [["blk", 11], ["dmg_blk"], ["apply", "sapped", 1]], "art": "mountain"},
	"last_stand": {"n": "Last Stand", "h": 0, "r": 3, "t": 1, "c": 1, "fx": [["blk", 12], ["buff", "str", 2]], "art": "crown", "x": true},
	# ------------------------------------------------ Nyx, the Thornwitch
	"thorn_lash": {"n": "Thorn Lash", "h": 1, "r": 0, "t": 0, "c": 1, "fx": [["dmg", 6]], "art": "fang"},
	"bark_skin": {"n": "Bark Skin", "h": 1, "r": 0, "t": 1, "c": 1, "fx": [["blk", 5]], "art": "leaf"},
	"venom_dart": {"n": "Venom Dart", "h": 1, "r": 0, "t": 0, "c": 1, "fx": [["dmg", 3], ["apply", "poison", 4]], "art": "drop"},
	"spore_cloud": {"n": "Spore Cloud", "h": 1, "r": 1, "t": 1, "c": 1, "fx": [["apply_all", "poison", 3]], "art": "cyclone"},
	"briar_whip": {"n": "Briar Whip", "h": 1, "r": 1, "t": 0, "c": 1, "fx": [["dmg", 8], ["apply", "sapped", 1]], "art": "leaf"},
	"quickroot": {"n": "Quickroot", "h": 1, "r": 1, "t": 1, "c": 1, "fx": [["blk", 3], ["draw", 2]], "art": "leaf"},
	"nettle_volley": {"n": "Nettle Volley", "h": 1, "r": 1, "t": 0, "c": 1, "fx": [["multi", 3, 3]], "art": "fang"},
	"sap_leech": {"n": "Sap Leech", "h": 1, "r": 1, "t": 0, "c": 1, "fx": [["dmg", 6], ["heal", 2]], "art": "heart"},
	"mossguard": {"n": "Mossguard", "h": 1, "r": 1, "t": 1, "c": 1, "fx": [["blk", 8]], "art": "leaf"},
	"toxic_needle": {"n": "Toxic Needle", "h": 1, "r": 1, "t": 0, "c": 0, "fx": [["dmg", 3], ["apply", "poison", 2]], "art": "drop"},
	"wither": {"n": "Wither", "h": 1, "r": 1, "t": 1, "c": 1, "fx": [["apply", "sapped", 2], ["apply", "poison", 3]], "art": "skull"},
	"leaf_veil": {"n": "Leaf Veil", "h": 1, "r": 1, "t": 1, "c": 0, "fx": [["blk", 4]], "art": "leaf"},
	"creeping_vine": {"n": "Creeping Vine", "h": 1, "r": 1, "t": 0, "c": 2, "fx": [["dmg_all", 7], ["apply_all", "poison", 2]], "art": "spiral"},
	"bramble_snare": {"n": "Bramble Snare", "h": 1, "r": 1, "t": 1, "c": 1, "fx": [["blk", 6], ["buff", "spikes", 2]], "art": "fang"},
	"rot_burst": {"n": "Rot Burst", "h": 1, "r": 1, "t": 0, "c": 1, "fx": [["dmg_poison", 1]], "art": "burst", "u": [["dmg_poison", 1], ["apply", "poison", 2]]},
	"fleetfoot": {"n": "Fleetfoot", "h": 1, "r": 2, "t": 1, "c": 1, "fx": [["buff", "agi", 2]], "art": "wave", "x": true},
	"plague_bloom": {"n": "Plague Bloom", "h": 1, "r": 2, "t": 2, "c": 1, "fx": [["power", "bloom", 2]], "art": "spiral", "lock": 1},
	"catalyst": {"n": "Catalyst", "h": 1, "r": 2, "t": 1, "c": 1, "fx": [["poison_mult", 2]], "art": "drop", "x": true, "u": [["poison_mult", 3]]},
	"nightshade": {"n": "Nightshade", "h": 1, "r": 2, "t": 0, "c": 2, "fx": [["dmg", 6], ["apply", "poison", 7]], "art": "moon"},
	"verdant_regrowth": {"n": "Verdant Regrowth", "h": 1, "r": 2, "t": 1, "c": 1, "fx": [["buff", "regen", 4]], "art": "heart", "x": true},
	"shadowstep": {"n": "Shadowstep", "h": 1, "r": 2, "t": 1, "c": 1, "fx": [["blk", 8], ["draw", 1]], "art": "moon"},
	"wild_growth": {"n": "Wild Growth", "h": 1, "r": 2, "t": 2, "c": 1, "fx": [["power", "spark", 1]], "art": "leaf", "uc": 0},
	"corrode": {"n": "Corrode", "h": 1, "r": 2, "t": 0, "c": 1, "fx": [["dmg", 7], ["apply", "vuln", 2]], "art": "drop"},
	"moth_swarm": {"n": "Moth Swarm", "h": 1, "r": 2, "t": 0, "c": 1, "fx": [["multi", 2, 5]], "art": "moon", "lock": 2},
	"toxic_tide": {"n": "Toxic Tide", "h": 1, "r": 2, "t": 1, "c": 2, "fx": [["apply_all", "poison", 6]], "art": "wave"},
	"deathcap": {"n": "Deathcap", "h": 1, "r": 3, "t": 1, "c": 1, "fx": [["apply", "poison", 10]], "art": "skull", "x": true},
	"blight_storm": {"n": "Blight Storm", "h": 1, "r": 3, "t": 1, "c": 2, "fx": [["apply_all", "poison", 7], ["apply_all", "sapped", 2]], "art": "cyclone", "lock": 3},
	"envenom": {"n": "Envenom", "h": 1, "r": 3, "t": 2, "c": 2, "fx": [["power", "envenom", 1]], "art": "fang", "uc": 1},
	"evergreen": {"n": "Evergreen", "h": 1, "r": 3, "t": 2, "c": 2, "fx": [["buff", "agi", 3]], "art": "leaf", "lock": 4},
	"thousand_thorns": {"n": "Thousand Thorns", "h": 1, "r": 3, "t": 0, "c": 2, "fx": [["multi", 3, 6]], "art": "burst"},
	# ------------------------------------------------ Orrin, the Starweaver
	"star_bolt": {"n": "Star Bolt", "h": 2, "r": 0, "t": 0, "c": 1, "fx": [["dmg", 6]], "art": "star"},
	"aether_ward": {"n": "Aether Ward", "h": 2, "r": 0, "t": 1, "c": 1, "fx": [["blk", 5]], "art": "orb"},
	"comet_shard": {"n": "Comet Shard", "h": 2, "r": 0, "t": 0, "c": 1, "fx": [["dmg", 4], ["add_card", "star_mote", 1]], "art": "comet"},
	"meteor_shower": {"n": "Meteor Shower", "h": 2, "r": 1, "t": 0, "c": 2, "fx": [["dmg_all", 9]], "art": "comet"},
	"glimmer": {"n": "Glimmer", "h": 2, "r": 1, "t": 1, "c": 0, "fx": [["draw", 2]], "art": "star", "x": true},
	"astral_lance": {"n": "Astral Lance", "h": 2, "r": 1, "t": 0, "c": 1, "fx": [["dmg", 9]], "art": "bolt"},
	"prism_shield": {"n": "Prism Shield", "h": 2, "r": 1, "t": 1, "c": 1, "fx": [["blk", 7], ["add_card", "star_mote", 1]], "art": "orb"},
	"starfall": {"n": "Starfall", "h": 2, "r": 1, "t": 0, "c": 1, "fx": [["multi", 4, 2]], "art": "star"},
	"gravity_well": {"n": "Gravity Well", "h": 2, "r": 1, "t": 1, "c": 1, "fx": [["blk", 5], ["apply_all", "sapped", 1]], "art": "spiral"},
	"mana_spring": {"n": "Mana Spring", "h": 2, "r": 1, "t": 1, "c": 0, "fx": [["energy", 1]], "art": "wave", "x": true, "u": [["energy", 1], ["draw", 1]]},
	"orbit_guard": {"n": "Orbit Guard", "h": 2, "r": 1, "t": 1, "c": 1, "fx": [["blk", 6], ["draw", 1]], "art": "orb"},
	"nova_flash": {"n": "Nova Flash", "h": 2, "r": 1, "t": 0, "c": 1, "fx": [["dmg_all", 5], ["apply_all", "vuln", 1]], "art": "burst"},
	"constellation": {"n": "Constellation", "h": 2, "r": 1, "t": 1, "c": 1, "fx": [["add_card", "star_mote", 3]], "art": "star"},
	"eclipse_ray": {"n": "Eclipse Ray", "h": 2, "r": 1, "t": 0, "c": 2, "fx": [["dmg", 12], ["apply", "vuln", 2]], "art": "moon"},
	"stardust_veil": {"n": "Stardust Veil", "h": 2, "r": 1, "t": 1, "c": 1, "fx": [["blk", 8]], "art": "star"},
	"echo_rune": {"n": "Echo Rune", "h": 2, "r": 2, "t": 1, "c": 1, "fx": [["buff", "echo", 1]], "art": "rune", "uc": 0},
	"astral_font": {"n": "Astral Font", "h": 2, "r": 2, "t": 2, "c": 2, "fx": [["power", "font", 1]], "art": "wave", "lock": 1},
	"mote_forge": {"n": "Mote Forge", "h": 2, "r": 2, "t": 2, "c": 1, "fx": [["power", "moteforge", 1]], "art": "gear"},
	"singularity": {"n": "Singularity", "h": 2, "r": 2, "t": 0, "c": 1, "fx": [["dmg_hand", 3]], "art": "spiral"},
	"quasar_burst": {"n": "Quasar Burst", "h": 2, "r": 2, "t": 0, "c": 2, "fx": [["multi", 5, 3]], "art": "burst"},
	"time_fold": {"n": "Time Fold", "h": 2, "r": 2, "t": 1, "c": 1, "fx": [["draw", 3]], "art": "rune"},
	"celestial_aegis": {"n": "Celestial Aegis", "h": 2, "r": 2, "t": 1, "c": 2, "fx": [["blk", 14]], "art": "orb"},
	"starlens": {"n": "Starlens", "h": 2, "r": 2, "t": 2, "c": 1, "fx": [["buff", "str", 2]], "art": "eye", "lock": 2},
	"cosmic_tide": {"n": "Cosmic Tide", "h": 2, "r": 2, "t": 0, "c": 1, "fx": [["dmg_all", 6], ["add_card", "star_mote", 1]], "art": "wave"},
	"weave_light": {"n": "Weave Light", "h": 2, "r": 2, "t": 1, "c": 1, "fx": [["blk", 5], ["energy", 1]], "art": "rune"},
	"supernova": {"n": "Supernova", "h": 2, "r": 3, "t": 0, "c": 3, "fx": [["dmg_all", 24]], "art": "burst", "x": true},
	"grand_orrery": {"n": "Grand Orrery", "h": 2, "r": 3, "t": 2, "c": 3, "fx": [["power", "orrery", 1]], "art": "orb", "uc": 2, "lock": 3},
	"black_hole": {"n": "Black Hole", "h": 2, "r": 3, "t": 1, "c": 2, "fx": [["apply_all", "vuln", 3], ["apply_all", "sapped", 3]], "art": "spiral", "x": true},
	"falling_wish": {"n": "Falling Wish", "h": 2, "r": 3, "t": 1, "c": 0, "fx": [["energy", 2], ["draw", 2]], "art": "comet", "x": true, "lock": 4},
	"zenith_beam": {"n": "Zenith Beam", "h": 2, "r": 3, "t": 0, "c": 2, "fx": [["dmg", 18], ["draw", 2]], "art": "bolt"},
	# ------------------------------------------------ tokens and curses
	"star_mote": {"n": "Star Mote", "h": -1, "r": 4, "t": 0, "c": 0, "fx": [["dmg", 3]], "art": "star", "x": true},
	"doubt": {"n": "Hollow Doubt", "h": -1, "r": 4, "t": 3, "c": -1, "fx": [], "art": "eye"},
}

const STATUS := {
	"str": {"n": "Strength", "d": "Attacks deal +N damage.", "col": Color("ff6b4a"), "good": true},
	"agi": {"n": "Agility", "d": "Gain +N Block from cards.", "col": Color("6be0ff"), "good": true},
	"vuln": {"n": "Vulnerable", "d": "Takes 50% more attack damage. Fades by 1 each turn.", "col": Color("ff9a3a"), "good": false},
	"sapped": {"n": "Sapped", "d": "Deals 25% less attack damage. Fades by 1 each turn.", "col": Color("b08cff"), "good": false},
	"poison": {"n": "Poison", "d": "Loses N HP at the start of its turn, then Poison drops by 1.", "col": Color("8cff5a"), "good": false},
	"regen": {"n": "Regen", "d": "Heals N HP at the end of the turn, then drops by 1.", "col": Color("ff8fc8"), "good": true},
	"spikes": {"n": "Spikes", "d": "Attackers take N damage per hit.", "col": Color("e8e0b0"), "good": true},
	"echo": {"n": "Echo", "d": "The next card played is cast twice.", "col": Color("ffe27a"), "good": true},
}

const POWERS := {
	"fortress": {"n": "Fortress", "d": "Block is no longer removed at the start of your turn."},
	"rage": {"n": "Rage", "d": "At the start of your turn, gain N Strength."},
	"rampart": {"n": "Rampart", "d": "At the start of your turn, gain N Block."},
	"bloom": {"n": "Bloom", "d": "At the start of your turn, apply N Poison to ALL enemies."},
	"spark": {"n": "Growth", "d": "Draw N extra card(s) each turn."},
	"font": {"n": "Font", "d": "Gain N extra Energy each turn."},
	"moteforge": {"n": "Mote Forge", "d": "At the start of your turn, add N Star Mote(s) to your hand."},
	"envenom": {"n": "Envenom", "d": "Each attack hit also applies N Poison."},
	"orrery": {"n": "Orrery", "d": "The first card you play each turn is cast twice."},
}

const RARITY_NAMES := ["Starter", "Common", "Uncommon", "Rare", "Special"]
const TYPE_NAMES := ["Attack", "Skill", "Power", "Curse"]


static func card(id: String) -> Dictionary:
	return CARDS.get(id, CARDS["doubt"])


## Effects of a card, taking upgrades into account.
static func fx_of(id: String, up: bool) -> Array:
	var c := card(id)
	if not up:
		return c["fx"]
	if c.has("u"):
		return c["u"]
	if c.has("uc") and c["uc"] < c["c"]:
		return c["fx"]
	var out: Array = []
	for op in c["fx"]:
		var o: Array = op.duplicate()
		match o[0]:
			"dmg", "dmg_all", "blk":
				o[1] += maxi(3, roundi(o[1] * 0.34))
			"multi", "multi_all":
				o[1] += 1 if o[2] < 4 else 0
				if o[2] >= 4:
					o[2] += 1
			"apply", "apply_all", "buff", "heal", "add_card":
				o[o.size() - 1] += 1
			"power":
				if o[1] in ["rampart", "bloom"]:
					o[2] += 2
				elif o[1] == "rage" and o[2] == 2:
					o[2] = 3
			"dmg_hand":
				o[1] += 1
			"draw":
				o[1] += 1
			"dmg_poison":
				o[1] += 1
		out.append(o)
	return out


static func cost_of(id: String, up: bool) -> int:
	var c := card(id)
	if up and c.has("uc"):
		return c["uc"]
	if up and not c.has("u") and fx_of(id, true) == c["fx"] and c["c"] > 0:
		return c["c"] - 1
	return c["c"]


static func needs_target(id: String) -> bool:
	for op in card(id)["fx"]:
		if op[0] in ["dmg", "multi", "apply", "dmg_blk", "dmg_poison", "poison_mult", "dmg_hand"]:
			return true
	return false


static func display_name(id: String, up: bool) -> String:
	return card(id)["n"] + ("+" if up else "")


## Rules text. `str_bonus` adds the player's Strength to attack numbers.
static func text(id: String, up: bool, str_bonus := 0, sapped := false) -> String:
	var c := card(id)
	if c["t"] == 3:
		return "Unplayable.\nClutters your hand."
	var parts: PackedStringArray = []
	for op in fx_of(id, up):
		parts.append(op_text(op, str_bonus, sapped))
	if c.get("x", false):
		parts.append("Exhaust.")
	return "\n".join(parts)


static func _d(n: int, sb: int, sap: bool) -> int:
	var v := n + sb
	if sap:
		v = int(floor(v * 0.75))
	return maxi(0, v)


static func op_text(op: Array, sb := 0, sap := false) -> String:
	match op[0]:
		"dmg":
			return "Deal %d damage." % _d(op[1], sb, sap)
		"dmg_all":
			return "Deal %d damage to ALL enemies." % _d(op[1], sb, sap)
		"multi":
			return "Deal %d damage %d times." % [_d(op[1], sb, sap), op[2]]
		"multi_all":
			return "Deal %d damage to ALL enemies %d times." % [_d(op[1], sb, sap), op[2]]
		"blk":
			return "Gain %d Block." % op[1]
		"draw":
			return "Draw %d card%s." % [op[1], "" if op[1] == 1 else "s"]
		"energy":
			return "Gain %d Energy." % op[1]
		"apply":
			return "Apply %d %s." % [op[2], STATUS[op[1]]["n"]]
		"apply_all":
			return "Apply %d %s to ALL enemies." % [op[2], STATUS[op[1]]["n"]]
		"buff":
			if op[1] == "echo":
				return "Your next card is cast twice." if op[2] == 1 else "Your next %d cards are cast twice." % op[2]
			return "Gain %d %s." % [op[2], STATUS[op[1]]["n"]]
		"heal":
			return "Heal %d HP." % op[1]
		"lose_hp":
			return "Lose %d HP." % op[1]
		"dmg_blk":
			return "Deal damage equal to your Block."
		"dmg_poison":
			return "Deal damage equal to the target's Poison." if op[1] == 1 else "Deal %dx the target's Poison as damage." % op[1]
		"poison_mult":
			return "%s the target's Poison." % ("Double" if op[1] == 2 else "Triple")
		"dmg_hand":
			return "Deal %d damage per card in your hand." % _d(op[1], 0, false)
		"add_card":
			return "Add %d %s to your hand." % [op[2], card(op[1])["n"] + ("" if op[2] == 1 else "s")]
		"power":
			return POWERS[op[1]]["d"].replace("N", str(op[2]))
	return ""


static func pool(hero: int, rarity: int, unlocked: int) -> Array:
	var out: Array = []
	for id in CARDS:
		var c: Dictionary = CARDS[id]
		if c["h"] == hero and c["r"] == rarity and int(c.get("lock", 0)) <= unlocked:
			out.append(id)
	return out


static func hero_cards(hero: int) -> Array:
	var out: Array = []
	for id in CARDS:
		if CARDS[id]["h"] == hero:
			out.append(id)
	return out
