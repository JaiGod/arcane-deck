extends RefCounted
## Arcane Deck - enemies, encounters, relics and events. All original.
## Enemy moves: {"n": name, "fx": [ops]}; ops: atk n times, blk n, buff st n,
## buff_all st n, debuff st n, heal n, summon id, doubt n, blk_all n.
## "pat" = fixed move cycle; otherwise moves are chosen at random without
## repeating the same move three times in a row.

const ACTS := [
	{"name": "The Mirewood", "sub": "Act I", "sky": Color("0e1f1a"), "sky2": Color("23422f"), "acc": Color("9be37a")},
	{"name": "The Glass Wastes", "sub": "Act II", "sky": Color("2a1a14"), "sky2": Color("6a3d26"), "acc": Color("ffc56b")},
	{"name": "The Star Vault", "sub": "Act III", "sky": Color("0b0a22"), "sky2": Color("2a1d5c"), "acc": Color("b49cff")},
]

const ENEMIES := {
	# ---------------------------------------------------------- Act I
	"bog_lurker": {"n": "Bog Lurker", "hp": [40, 45], "shape": "blob", "col": Color("4f7a3a"), "col2": Color("2a3f22"), "sz": 1.1,
		"moves": [{"n": "Chomp", "fx": [["atk", 11]]}, {"n": "Wallow", "fx": [["blk", 8], ["buff", "str", 2]]}, {"n": "Mud Spit", "fx": [["atk", 6], ["debuff", "sapped", 2]]}]},
	"spore_puff": {"n": "Spore Puff", "hp": [11, 15], "shape": "puff", "col": Color("c98bd6"), "col2": Color("6a3d7a"), "sz": 0.7,
		"moves": [{"n": "Bump", "fx": [["atk", 5]]}, {"n": "Spore Spray", "fx": [["debuff", "poison", 2]]}]},
	"rust_beetle": {"n": "Rust Beetle", "hp": [28, 32], "shape": "bug", "col": Color("b8642e"), "col2": Color("5a2e16"), "sz": 0.95,
		"moves": [{"n": "Snap", "fx": [["atk", 7]]}, {"n": "Harden", "fx": [["blk", 10]]}, {"n": "Corrode", "fx": [["atk", 4], ["debuff", "vuln", 1]]}]},
	"gnash_hound": {"n": "Gnash Hound", "hp": [22, 26], "shape": "beast", "col": Color("6b5a4a"), "col2": Color("30261d"), "sz": 0.9,
		"moves": [{"n": "Double Bite", "fx": [["atk", 5, 2]]}, {"n": "Howl", "fx": [["buff", "str", 2]]}]},
	"mire_imp": {"n": "Mire Imp", "hp": [16, 20], "shape": "imp", "col": Color("5aa06a"), "col2": Color("244a2d"), "sz": 0.75,
		"moves": [{"n": "Prick", "fx": [["atk", 6]]}, {"n": "Hex", "fx": [["debuff", "vuln", 2], ["atk", 2]]}]},
	"mosshide_brute": {"n": "Mosshide Brute", "hp": [82, 88], "shape": "brute", "col": Color("4d6b34"), "col2": Color("26361a"), "sz": 1.35, "elite": true,
		"moves": [{"n": "Maul", "fx": [["atk", 15]]}, {"n": "Bellow", "fx": [["buff", "str", 3], ["blk", 6]]}, {"n": "Trample", "fx": [["atk", 7, 2]]}], "pat": [1, 0, 2, 0]},
	"twin_wisp": {"n": "Will Wisp", "hp": [32, 36], "shape": "wisp", "col": Color("7af0ff"), "col2": Color("1f5a7a"), "sz": 0.85, "elite": true,
		"moves": [{"n": "Flicker", "fx": [["atk", 7], ["debuff", "sapped", 1]]}, {"n": "Kindle", "fx": [["buff_all", "str", 2]]}, {"n": "Searing Glow", "fx": [["atk", 12]]}]},
	"rootmother": {"n": "The Rootmother", "hp": [150, 150], "shape": "tree", "col": Color("6b4a2a"), "col2": Color("2e1e10"), "sz": 1.8, "boss": true,
		"moves": [{"n": "Entangle", "fx": [["atk", 8], ["debuff", "sapped", 2]]}, {"n": "Crushing Grasp", "fx": [["atk", 16]]}, {"n": "Sprout", "fx": [["summon", "spore_puff"], ["blk", 10]]}, {"n": "Root Lash", "fx": [["atk", 6, 3]]}, {"n": "Deep Growth", "fx": [["buff", "str", 3], ["heal", 10]]}],
		"pat": [0, 2, 1, 3, 4, 1, 3]},
	# ---------------------------------------------------------- Act II
	"shardling": {"n": "Shardling", "hp": [30, 34], "shape": "crystal", "col": Color("9fe8ff"), "col2": Color("3a6a8a"), "sz": 0.8,
		"moves": [{"n": "Splinter", "fx": [["atk", 4, 3]]}, {"n": "Refract", "fx": [["blk", 12]]}]},
	"dune_stalker": {"n": "Dune Stalker", "hp": [50, 56], "shape": "beast", "col": Color("c9a26a"), "col2": Color("6a4a26"), "sz": 1.05,
		"moves": [{"n": "Ambush", "fx": [["atk", 17]]}, {"n": "Burrow", "fx": [["blk", 15]]}, {"n": "Lacerate", "fx": [["atk", 9], ["debuff", "vuln", 2]]}], "pat": [0, 1, 2]},
	"ash_cultist": {"n": "Ash Cultist", "hp": [44, 48], "shape": "cultist", "col": Color("a8473a"), "col2": Color("3a1a18"), "sz": 1.0,
		"moves": [{"n": "Ember Chant", "fx": [["buff", "str", 3]]}, {"n": "Ash Bolt", "fx": [["atk", 10]]}, {"n": "Smother", "fx": [["debuff", "sapped", 2], ["debuff", "vuln", 1]]}], "pat": [0, 1, 1, 2]},
	"mirror_mite": {"n": "Mirror Mite", "hp": [24, 28], "shape": "bug", "col": Color("d6e4f0"), "col2": Color("6a7a8a"), "sz": 0.75,
		"moves": [{"n": "Nip", "fx": [["atk", 8]]}, {"n": "Glint", "fx": [["blk", 8], ["buff", "spikes", 2]]}]},
	"sand_viper": {"n": "Sand Viper", "hp": [38, 42], "shape": "serpent", "col": Color("d9b45a"), "col2": Color("6a5420"), "sz": 0.95,
		"moves": [{"n": "Venom Fang", "fx": [["atk", 6], ["debuff", "poison", 4]]}, {"n": "Coil Strike", "fx": [["atk", 12]]}]},
	"prism_golem": {"n": "Prism Golem", "hp": [140, 150], "shape": "golem", "col": Color("8fd0ff"), "col2": Color("2a4a7a"), "sz": 1.45, "elite": true,
		"moves": [{"n": "Prism Beam", "fx": [["atk", 22]]}, {"n": "Fracture", "fx": [["atk", 8, 3]]}, {"n": "Polish", "fx": [["blk", 20], ["buff", "str", 2]]}], "pat": [2, 0, 1]},
	"sandwyrm": {"n": "Sandwyrm", "hp": [120, 128], "shape": "serpent", "col": Color("b8823a"), "col2": Color("5a3a18"), "sz": 1.5, "elite": true,
		"moves": [{"n": "Devour", "fx": [["atk", 21]]}, {"n": "Coil", "fx": [["blk", 15], ["buff", "str", 3]]}, {"n": "Tail Sweep", "fx": [["atk", 10], ["debuff", "vuln", 2]]}]},
	"glass_tyrant": {"n": "The Glass Tyrant", "hp": [250, 250], "shape": "golem", "col": Color("e8f4ff"), "col2": Color("4a6a9a"), "sz": 1.85, "boss": true,
		"moves": [{"n": "Shatter Storm", "fx": [["atk", 9, 3]]}, {"n": "Cruel Edict", "fx": [["debuff", "vuln", 3], ["debuff", "sapped", 2], ["doubt", 1]]}, {"n": "Crystallize", "fx": [["blk", 30], ["buff", "str", 3]]}, {"n": "Execution", "fx": [["atk", 28]]}],
		"pat": [1, 0, 2, 3, 0, 2, 3]},
	# ---------------------------------------------------------- Act III
	"void_acolyte": {"n": "Void Acolyte", "hp": [58, 64], "shape": "cultist", "col": Color("6a4ab8"), "col2": Color("1e1440"), "sz": 1.0,
		"moves": [{"n": "Drain", "fx": [["atk", 12], ["heal", 6]]}, {"n": "Whisper", "fx": [["doubt", 1], ["debuff", "sapped", 2]]}, {"n": "Void Lance", "fx": [["atk", 16]]}]},
	"clock_sentinel": {"n": "Clock Sentinel", "hp": [68, 74], "shape": "clock", "col": Color("c9a24a"), "col2": Color("4a3a18"), "sz": 1.1,
		"moves": [{"n": "Gear Strike", "fx": [["atk", 14]]}, {"n": "Wind Up", "fx": [["buff", "str", 4], ["blk", 10]]}, {"n": "Overclock", "fx": [["atk", 6, 4]]}], "pat": [0, 1, 2]},
	"star_leech": {"n": "Star Leech", "hp": [42, 46], "shape": "blob", "col": Color("ff7ac8"), "col2": Color("5a1e4a"), "sz": 0.9,
		"moves": [{"n": "Siphon", "fx": [["atk", 9], ["debuff", "poison", 4]]}, {"n": "Swell", "fx": [["blk", 12], ["heal", 5]]}]},
	"hex_lantern": {"n": "Hex Lantern", "hp": [36, 40], "shape": "lantern", "col": Color("ffb84a"), "col2": Color("4a2a10"), "sz": 0.85,
		"moves": [{"n": "Hex", "fx": [["debuff", "vuln", 3]]}, {"n": "Flare", "fx": [["atk", 17]]}], "pat": [0, 1, 1]},
	"eclipse_knight": {"n": "Eclipse Knight", "hp": [190, 200], "shape": "knight", "col": Color("3a3a5a"), "col2": Color("12121e"), "sz": 1.5, "elite": true,
		"moves": [{"n": "Umbral Slash", "fx": [["atk", 27]]}, {"n": "Night Guard", "fx": [["blk", 26], ["buff", "str", 2]]}, {"n": "Nightfall", "fx": [["atk", 10, 3], ["debuff", "sapped", 1]]}], "pat": [1, 0, 2]},
	"nebula_hydra": {"n": "Nebula Hydra", "hp": [170, 178], "shape": "serpent", "col": Color("7a5aff"), "col2": Color("2a1a6a"), "sz": 1.5, "elite": true,
		"moves": [{"n": "Three Heads", "fx": [["atk", 8, 3]]}, {"n": "Regrow", "fx": [["heal", 20], ["buff", "str", 2]]}, {"n": "Star Venom", "fx": [["atk", 10], ["debuff", "poison", 5]]}]},
	"the_unwoven": {"n": "The Unwoven", "hp": [360, 360], "shape": "void", "col": Color("b49cff"), "col2": Color("1a0e3a"), "sz": 2.0, "boss": true,
		"moves": [{"n": "Unravel", "fx": [["atk", 12, 3]]}, {"n": "Erase", "fx": [["debuff", "vuln", 3], ["debuff", "sapped", 3], ["doubt", 2]]}, {"n": "Void Bulwark", "fx": [["blk", 40], ["buff", "str", 4]]}, {"n": "Final Thread", "fx": [["atk", 46]]}, {"n": "Call the Lost", "fx": [["summon", "void_acolyte"], ["blk", 20]]}],
		"pat": [1, 0, 2, 3, 4, 0, 2, 3]},
}

const ENCOUNTERS := [
	{"easy": [["spore_puff", "spore_puff"], ["mire_imp", "mire_imp"], ["gnash_hound"], ["rust_beetle"]],
		"normal": [["bog_lurker"], ["spore_puff", "spore_puff", "spore_puff"], ["rust_beetle", "mire_imp"], ["gnash_hound", "spore_puff"], ["mire_imp", "mire_imp", "spore_puff"], ["gnash_hound", "gnash_hound"]],
		"elite": [["mosshide_brute"], ["twin_wisp", "twin_wisp"]], "boss": ["rootmother"]},
	{"easy": [["shardling", "shardling"], ["sand_viper"], ["mirror_mite", "mirror_mite"]],
		"normal": [["dune_stalker"], ["ash_cultist", "mirror_mite"], ["shardling", "sand_viper"], ["ash_cultist", "ash_cultist"], ["mirror_mite", "mirror_mite", "shardling"], ["sand_viper", "dune_stalker"]],
		"elite": [["prism_golem"], ["sandwyrm"]], "boss": ["glass_tyrant"]},
	{"easy": [["star_leech", "hex_lantern"], ["void_acolyte"], ["clock_sentinel"]],
		"normal": [["void_acolyte", "star_leech"], ["clock_sentinel", "hex_lantern"], ["star_leech", "star_leech", "hex_lantern"], ["void_acolyte", "void_acolyte"], ["clock_sentinel", "star_leech"]],
		"elite": [["eclipse_knight"], ["nebula_hydra"]], "boss": ["the_unwoven"]},
]

## Relics. tier: 0 starter, 1 common, 2 rare, 3 boss.
const RELICS := {
	"ember_heart": {"n": "Ember Heart", "d": "Heal 6 HP after each combat.", "tier": 0, "art": "heart", "col": Color("ff7a3d")},
	"seed_of_rot": {"n": "Seed of Rot", "d": "At the start of combat, apply 2 Poison to ALL enemies.", "tier": 0, "art": "drop", "col": Color("7be36a")},
	"orrery_shard": {"n": "Orrery Shard", "d": "Gain 1 extra Energy on the first turn of combat.", "tier": 0, "art": "orb", "col": Color("7aa8ff")},
	"whetstone": {"n": "Whetstone", "d": "Start each combat with 1 Strength.", "tier": 1, "art": "blade", "col": Color("c8c8d8")},
	"bark_amulet": {"n": "Bark Amulet", "d": "Start each combat with 7 Block.", "tier": 1, "art": "leaf", "col": Color("9b7a4a")},
	"lucky_coin": {"n": "Lucky Coin", "d": "Gain 25% more gold from combat.", "tier": 1, "art": "orb", "col": Color("ffd54a")},
	"vigor_root": {"n": "Vigor Root", "d": "Raise your Max HP by 10.", "tier": 1, "art": "heart", "col": Color("ff8fc8")},
	"feather_quill": {"n": "Feather Quill", "d": "Draw 2 extra cards on the first turn of combat.", "tier": 1, "art": "wave", "col": Color("e8f0ff")},
	"pendulum": {"n": "Pendulum", "d": "Every 3rd turn, gain 1 extra Energy.", "tier": 1, "art": "gear", "col": Color("d9b45a")},
	"bone_dice": {"n": "Bone Dice", "d": "At the start of combat, apply 1 Vulnerable to ALL enemies.", "tier": 1, "art": "skull", "col": Color("efe6d0")},
	"thorn_ring": {"n": "Thorn Ring", "d": "Start each combat with 3 Spikes.", "tier": 1, "art": "fang", "col": Color("8ab86a")},
	"hearth_stone": {"n": "Hearth Stone", "d": "Resting heals an extra 15% of your Max HP.", "tier": 1, "art": "flame", "col": Color("ff9a4a")},
	"merchant_seal": {"n": "Merchant's Seal", "d": "Shop prices are 20% lower.", "tier": 1, "art": "crown", "col": Color("ffcf6a")},
	"storm_bell": {"n": "Storm Bell", "d": "Every 3rd attack you play deals 5 damage to ALL enemies.", "tier": 2, "art": "bolt", "col": Color("7af0ff")},
	"leech_fang": {"n": "Leech Fang", "d": "Heal 3 HP whenever an enemy dies.", "tier": 2, "art": "fang", "col": Color("ff5a7a")},
	"hydra_scale": {"n": "Hydra Scale", "d": "Whenever you apply Poison, apply 1 more.", "tier": 2, "art": "drop", "col": Color("5aff9a")},
	"mirror_veil": {"n": "Mirror Veil", "d": "If you end your turn with no Block, gain 6 Block.", "tier": 2, "art": "eye", "col": Color("c8e4ff")},
	"ember_lamp": {"n": "Ember Lamp", "d": "Each unused Energy at the end of your turn grants 3 Block.", "tier": 2, "art": "flame", "col": Color("ffb84a")},
	"phoenix_plume": {"n": "Phoenix Plume", "d": "The first time you would die, heal to 40% HP instead.", "tier": 2, "art": "comet", "col": Color("ff6a3a")},
	"sun_engine": {"n": "Sun Engine", "d": "Gain 1 extra Energy every turn. Start each combat with a Hollow Doubt in your draw pile.", "tier": 3, "art": "star", "col": Color("ffe27a")},
	"star_compass": {"n": "Star Compass", "d": "Draw 1 extra card every turn.", "tier": 3, "art": "star", "col": Color("b49cff")},
	"crown_of_ash": {"n": "Crown of Ash", "d": "Gain 1 extra Energy every turn. Lose 8 Max HP.", "tier": 3, "art": "crown", "col": Color("ff8a5a")},
	"aegis_core": {"n": "Aegis Core", "d": "Start each combat with 14 Block and 1 Agility.", "tier": 3, "art": "shield", "col": Color("8fd0ff")},
}

## Event choices: {"t": label, "fx": [ops], "need": gold}. Ops: heal n, hp -n,
## maxhp n, gold n, card_rare, card_choice, upgrade_rand n, remove_starter,
## relic, curse, dup, fight.
const EVENTS := [
	{"n": "The Weeping Shrine", "art": "eye", "d": "Rain falls upward around a cracked stone idol. It hums when you come close.",
		"ch": [{"t": "Pray  (heal 20 HP)", "fx": [["heal", 20]]}, {"t": "Offer blood  (lose 8 HP, gain a rare card)", "fx": [["hp", -8], ["card_rare"]]}, {"t": "Walk on", "fx": []}]},
	{"n": "The Wandering Tinker", "art": "gear", "d": "A tiny tinker on stilts offers to sharpen your tricks for a fee.",
		"ch": [{"t": "Pay 50 gold  (upgrade 2 random cards)", "fx": [["gold", -50], ["upgrade_rand", 2]], "need": 50}, {"t": "Trade a basic card away  (remove a starter card)", "fx": [["remove_starter"]]}, {"t": "Decline", "fx": []}]},
	{"n": "Glimmering Pool", "art": "wave", "d": "A pool of liquid starlight. Coins wink at the bottom, and something watches from below.",
		"ch": [{"t": "Drink  (+6 Max HP)", "fx": [["maxhp", 6]]}, {"t": "Dive for coins  (+90 gold, gain a Hollow Doubt)", "fx": [["gold", 90], ["curse"]]}, {"t": "Leave", "fx": []}]},
	{"n": "The Mushroom Ring", "art": "spiral", "d": "Glowing caps form a perfect circle. The air tastes like copper.",
		"ch": [{"t": "Eat one  (gain a relic, lose 10 HP)", "fx": [["hp", -10], ["relic"]]}, {"t": "Dance in the ring  (upgrade a random card)", "fx": [["upgrade_rand", 1]]}, {"t": "Step around it", "fx": []}]},
	{"n": "The Lost Courier", "art": "crown", "d": "A satchel sits next to a sleeping courier. It is heavy with coin.",
		"ch": [{"t": "Take the satchel  (+65 gold)", "fx": [["gold", 65]]}, {"t": "Wake them  (heal 10 HP, +30 gold)", "fx": [["heal", 10], ["gold", 30]]}]},
	{"n": "Hall of Mirrors", "art": "eye", "d": "A hundred reflections show you, each holding a different card.",
		"ch": [{"t": "Reach in  (duplicate a random card)", "fx": [["dup"]]}, {"t": "Shatter one  (remove a starter card, lose 5 HP)", "fx": [["hp", -5], ["remove_starter"]]}, {"t": "Look away", "fx": []}]},
	{"n": "The Ambush Camp", "art": "blade", "d": "A camp of brigands, asleep around a chest. Their guard is awake.",
		"ch": [{"t": "Fight the guard  (elite fight, relic reward)", "fx": [["fight"]]}, {"t": "Sneak a few coins  (+25 gold)", "fx": [["gold", 25]]}]},
	{"n": "The Ancient Library", "art": "rune", "d": "Dusty tomes stir as you enter. One of them flips open by itself.",
		"ch": [{"t": "Study  (choose 1 of 3 cards)", "fx": [["card_choice"]]}, {"t": "Nap in the stacks  (heal 14 HP)", "fx": [["heal", 14]]}]},
]

const NODE_NAMES := {"fight": "Combat", "elite": "Elite", "rest": "Campfire", "shop": "Merchant", "event": "Mystery", "treasure": "Treasure", "boss": "Boss"}
