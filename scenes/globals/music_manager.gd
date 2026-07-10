extends Node

const TRACKS = {
	"menu":             "res://assets/music/Scarlet Halls (BRM Menu and Lobby Theme).mp3",
	"title":            "res://assets/audio/music/title_screen.ogg",
	"character_select": "res://assets/audio/music/character_select.ogg",
	"loading":          "res://assets/audio/music/loading.ogg",
	"act9":             "res://assets/music/maps/______9 (Act 9 Map Theme).mp3",
	"2011x_chase":      "res://assets/music/characters/Chase/Drowning in Fear (2011X Normal Chase).mp3",
}

# Per-track volume offset in dB — negative = quieter, positive = louder
const TRACK_VOLUME_OFFSETS = {
	"menu":             0.0,
	"title":            0.0,
	"character_select": 0.0,
	"loading":          0.0,
	"act9":             4.0,    # map ambient was too quiet — boosted
	"2011x_chase":     -8.0,    # chase was too loud — reduced
}

const LOW_HEALTH_ALARM = "res://assets/audio/sfx/low_health_alarm.mp3"
const ALARM_VOLUME_DB = -10.0   # separate, quieter volume just for the alarm

var player := AudioStreamPlayer.new()
var alarm_player := AudioStreamPlayer.new()
var current_track := ""
var base_volume_db := 0.0   # set by the Settings music slider

var is_muffled := false
var muffle_bus_index := -1

func _ready():
	add_child(player)
	add_child(alarm_player)
	player.bus = "Music"
	alarm_player.bus = "Music"
	muffle_bus_index = AudioServer.get_bus_index("Music")
	_apply_volume()

func play(track_name: String, loop: bool = true):
	if current_track == track_name and player.playing:
		return
	if not TRACKS.has(track_name):
		push_warning("MusicManager: Track not found: " + track_name)
		stop()
		return
	if not ResourceLoader.exists(TRACKS[track_name]):
		push_warning("MusicManager: File not found: " + TRACKS[track_name])
		stop()
		return

	var stream = load(TRACKS[track_name])
	if stream is AudioStreamOggVorbis or stream is AudioStreamMP3:
		stream.loop = loop

	player.stream = stream
	current_track = track_name
	_apply_volume()
	player.play()

func stop():
	player.stop()
	current_track = ""

func set_volume(value: float):
	# Value from 0.0 to 1.0 — comes from the Settings music slider
	base_volume_db = linear_to_db(value)
	_apply_volume()

func _apply_volume():
	var offset = TRACK_VOLUME_OFFSETS.get(current_track, 0.0)
	player.volume_db = base_volume_db + offset

func fade_out(duration: float = 1.0):
	var tween = create_tween()
	tween.tween_property(player, "volume_db", -80.0, duration)
	tween.tween_callback(stop)

func fade_in(track_name: String, duration: float = 1.0):
	play(track_name)
	var target = base_volume_db + TRACK_VOLUME_OFFSETS.get(track_name, 0.0)
	player.volume_db = -80.0
	var tween = create_tween()
	tween.tween_property(player, "volume_db", target, duration)

# -- Low Health Muffle Effect ---------------------------------------------------------------------------
func set_muffled(muffled: bool):
	if is_muffled == muffled:
		return
	is_muffled = muffled

	if muffle_bus_index == -1:
		push_warning("MusicManager: 'Music' bus not found — add it in the Audio panel")
		return

	var effect = AudioServer.get_bus_effect(muffle_bus_index, 0)
	if effect == null or not (effect is AudioEffectLowPassFilter):
		push_warning("MusicManager: No LowPassFilter effect found on 'Music' bus")
		return

	# Less extreme muffle than before — 500 was too harsh, 1400 keeps some clarity
	var target_cutoff = 1400.0 if muffled else 20000.0
	var tween = create_tween()
	tween.tween_property(effect, "cutoff_hz", target_cutoff, 0.5)

# -- Low Health Alarm ------------------------------------------------------------------------------------
func start_low_health_alarm():
	if not ResourceLoader.exists(LOW_HEALTH_ALARM):
		push_warning("MusicManager: Alarm file not found: " + LOW_HEALTH_ALARM)
		return
	if alarm_player.playing:
		return
	var stream = load(LOW_HEALTH_ALARM)
	if stream is AudioStreamOggVorbis or stream is AudioStreamMP3:
		stream.loop = true
	alarm_player.stream = stream
	alarm_player.volume_db = base_volume_db + ALARM_VOLUME_DB
	alarm_player.play()

func stop_low_health_alarm():
	alarm_player.stop()
