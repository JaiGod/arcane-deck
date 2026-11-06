extends Node
## Arcane Deck - every sound is synthesized at startup into small WAV
## buffers (no audio files). A soft looping pad plays as music.

const RATE := 22050
var sounds := {}
var players: Array = []
var music: AudioStreamPlayer
var sound_on := true
var music_on := true
var _next := 0


func _ready() -> void:
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		players.append(p)
	sounds["click"] = _tone([[880, 0.04]], 0.25, "sine", 0.002, 0.04)
	sounds["card"] = _noise(0.12, 0.3, 2400.0)
	sounds["draw"] = _noise(0.06, 0.18, 4000.0)
	sounds["hit"] = _mix([_noise(0.16, 0.5, 900.0), _tone([[140, 0.0], [60, 0.14]], 0.5, "square", 0.002, 0.14)])
	sounds["big_hit"] = _mix([_noise(0.3, 0.6, 600.0), _tone([[110, 0.0], [40, 0.28]], 0.6, "square", 0.002, 0.28)])
	sounds["block"] = _tone([[520, 0.0], [700, 0.08]], 0.3, "tri", 0.002, 0.12)
	sounds["buff"] = _tone([[440, 0.0], [660, 0.06], [880, 0.12]], 0.25, "tri", 0.005, 0.2)
	sounds["debuff"] = _tone([[300, 0.0], [180, 0.2]], 0.3, "saw", 0.005, 0.22)
	sounds["poison"] = _tone([[200, 0.0], [260, 0.05], [190, 0.1]], 0.25, "sine", 0.005, 0.14)
	sounds["gold"] = _tone([[1320, 0.0], [1760, 0.05]], 0.25, "sine", 0.002, 0.16)
	sounds["heal"] = _tone([[523, 0.0], [659, 0.08], [784, 0.16]], 0.25, "sine", 0.01, 0.3)
	sounds["die"] = _mix([_noise(0.4, 0.4, 500.0), _tone([[300, 0.0], [50, 0.38]], 0.4, "saw", 0.002, 0.38)])
	sounds["turn"] = _tone([[392, 0.0], [523, 0.07]], 0.22, "tri", 0.005, 0.16)
	sounds["win"] = _tone([[523, 0.0], [659, 0.12], [784, 0.24], [1047, 0.36]], 0.3, "tri", 0.01, 0.6)
	sounds["lose"] = _tone([[392, 0.0], [330, 0.2], [262, 0.4], [196, 0.6]], 0.3, "saw", 0.01, 0.9)
	sounds["deny"] = _tone([[160, 0.0], [150, 0.1]], 0.25, "square", 0.002, 0.12)
	sounds["relic"] = _tone([[660, 0.0], [990, 0.06], [1320, 0.12], [1980, 0.18]], 0.22, "sine", 0.005, 0.4)
	music = AudioStreamPlayer.new()
	music.stream = _pad()
	music.volume_db = -14.0
	add_child(music)


func play(name: String, pitch := 1.0) -> void:
	if not sound_on or not sounds.has(name):
		return
	var p: AudioStreamPlayer = players[_next]
	_next = (_next + 1) % players.size()
	p.stream = sounds[name]
	p.pitch_scale = pitch * randf_range(0.96, 1.04)
	p.play()


func set_music(on: bool) -> void:
	music_on = on
	if on and not music.playing:
		music.play()
	elif not on:
		music.stop()


func _wav(data: PackedFloat32Array, loop := false) -> AudioStreamWAV:
	var b := PackedByteArray()
	b.resize(data.size() * 2)
	for i in data.size():
		b.encode_s16(i * 2, int(clampf(data[i], -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = b
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_end = data.size()
	return w


func _osc(kind: String, ph: float) -> float:
	match kind:
		"square":
			return 1.0 if fmod(ph, 1.0) < 0.5 else -1.0
		"saw":
			return fmod(ph, 1.0) * 2.0 - 1.0
		"tri":
			return abs(fmod(ph, 1.0) * 4.0 - 2.0) - 1.0
	return sin(ph * TAU)


## Pitch steps [[freq, start_time], ...] glide between each other.
func _tone(steps: Array, vol: float, kind: String, att: float, dur: float) -> AudioStreamWAV:
	var n := int(RATE * dur)
	var d := PackedFloat32Array()
	d.resize(n)
	var ph := 0.0
	for i in n:
		var t := float(i) / RATE
		var f: float = steps[0][0]
		for s in steps:
			if t >= s[1]:
				f = s[0]
		ph += f / RATE
		var env := minf(1.0, t / att) * pow(1.0 - float(i) / n, 2.0)
		d[i] = _osc(kind, ph) * env * vol
	return _wav(d)


func _noise(dur: float, vol: float, cutoff: float) -> AudioStreamWAV:
	var n := int(RATE * dur)
	var d := PackedFloat32Array()
	d.resize(n)
	var y := 0.0
	var a := clampf(cutoff / RATE * 6.0, 0.01, 1.0)
	for i in n:
		y += (randf() * 2.0 - 1.0 - y) * a
		d[i] = y * vol * 1.6 * pow(1.0 - float(i) / n, 2.0)
	return _wav(d)


func _mix(list: Array) -> AudioStreamWAV:
	var n := 0
	for w in list:
		n = maxi(n, w.data.size() / 2)
	var d := PackedFloat32Array()
	d.resize(n)
	for w in list:
		var b: PackedByteArray = w.data
		for i in b.size() / 2:
			d[i] += b.decode_s16(i * 2) / 32000.0
	return _wav(d)


## A slow, soft four-chord pad (8 seconds) that loops.
func _pad() -> AudioStreamWAV:
	var chords := [[220.0, 261.6, 329.6], [174.6, 220.0, 261.6], [196.0, 246.9, 293.7], [164.8, 207.7, 246.9]]
	var seg := RATE * 2
	var n := seg * 4
	var d := PackedFloat32Array()
	d.resize(n)
	var phs := [0.0, 0.0, 0.0, 0.0]
	for i in n:
		var ci := i / seg
		var k := float(i % seg) / seg
		var env := minf(1.0, k * 4.0) * minf(1.0, (1.0 - k) * 4.0) * 0.7 + 0.3
		var v := 0.0
		for j in 3:
			phs[j] += chords[ci][j] / RATE
			v += sin(phs[j] * TAU) + 0.3 * sin(phs[j] * TAU * 2.0)
		phs[3] += chords[ci][0] * 0.5 / RATE
		v += 0.6 * sin(phs[3] * TAU)
		d[i] = v * 0.08 * env
	return _wav(d, true)
