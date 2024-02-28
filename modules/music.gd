extends AudioStreamPlayer

var last_music_tick = Time.get_ticks_msec()
var tween
var disabled = true
var debounce = false

var music = [
	preload("res://music/headfooter.ogg"),
	preload("res://music/ALL_THE_SAME_FACE_-_THE_WHITE_HOUSE_IS_A_WHITE_HORSE_IS_A_PALE_HORSE_2.ogg"),
	preload("res://music/katie.ogg"),
	preload("res://music/marquis_de_sade_murder_party.ogg"),
	preload("res://music/grk.ogg"),
]

const MUSIC_TICKS = 25 * 1000 # after a track ends
const FADE_IN = 1

func stop_random():
	stop()
	disabled = true

func restart_random():
	if not disabled: return
	debounce = false
	disabled = false
	last_music_tick = Time.get_ticks_msec()

func quickstart_random():
	debounce = false
	disabled = false
	last_music_tick = Time.get_ticks_msec() - MUSIC_TICKS * 0.9

func _finished():
	last_music_tick = Time.get_ticks_msec() + randi() % MUSIC_TICKS
	debounce = false

func _process(_delta):
	if disabled: return
	if debounce: return
	if not playing and Time.get_ticks_msec() - last_music_tick > MUSIC_TICKS:
		stream = music.pick_random()
		volume_db = -80
		if tween:
			tween.kill()
		tween = create_tween()
		tween.tween_property(self, "volume_db", 0, FADE_IN).set_trans(Tween.TRANS_EXPO)
		debounce = true
		play()
