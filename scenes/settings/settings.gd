extends Control

# -- Onready ---------------------------------------------------------------------------------------------
@onready var back_btn = $Background/BackButton
@onready var tab_bar  = $Background/TabBar

@onready var identity_panel = $Background/SettingsContainer/IdentityPanel
@onready var visual_panel   = $Background/SettingsContainer/VisualPanel
@onready var audio_panel    = $Background/SettingsContainer/AudioPanel
@onready var access_panel   = $Background/SettingsContainer/AccessibilityPanel

# Identity
@onready var username_field = $Background/SettingsContainer/IdentityPanel/UsernameField
@onready var they_check     = $Background/SettingsContainer/IdentityPanel/PronounsContainer/TheyThemCheck
@onready var she_check      = $Background/SettingsContainer/IdentityPanel/PronounsContainer/SheHerCheck
@onready var he_check       = $Background/SettingsContainer/IdentityPanel/PronounsContainer/HeHimCheck
@onready var any_check      = $Background/SettingsContainer/IdentityPanel/PronounsContainer/AnyCheck

# Visual
@onready var resolution_option = $Background/SettingsContainer/VisualPanel/ResolutionOption
@onready var fullscreen_check  = $Background/SettingsContainer/VisualPanel/FullscreenCheck
@onready var vsync_check       = $Background/SettingsContainer/VisualPanel/VSyncCheck

# Audio
@onready var music_slider       = $Background/SettingsContainer/AudioPanel/MusicSlider
@onready var harsh_slider       = $Background/SettingsContainer/AudioPanel/HarshNoiseSlider
@onready var harsh_test_btn     = $Background/SettingsContainer/AudioPanel/HarshNoiseTest
@onready var harsh_noise_player = $Background/SettingsContainer/AudioPanel/HarshNoisePlayer
@onready var subtitles_check    = $Background/SettingsContainer/AudioPanel/SubtitlesCheck
@onready var lyrics_check       = $Background/SettingsContainer/AudioPanel/LyricsCheck

# Accessibility
@onready var no_gore_check     = $Background/SettingsContainer/AccessibilityPanel/NoGoreCheck
@onready var epilepsy_check    = $Background/SettingsContainer/AccessibilityPanel/EpilepsyCheck
@onready var streaming_warning = $Background/SettingsContainer/AccessibilityPanel/StreamingWarning
@onready var text_scale_slider = $Background/SettingsContainer/AccessibilityPanel/TextScaleSlider

# -- Resolutions -----------------------------------------------------------------------------------------
const RESOLUTIONS = [
	Vector2i(854,  480),
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160),
]

# -- Ready -----------------------------------------------------------------------------------------------
func _ready():
	# Visual setup MUST happen before _load_settings
	_setup_resolution_options()

	_load_settings()
	_check_streaming_apps()
	_show_panel(0)

	back_btn.pressed.connect(_on_back)
	tab_bar.tab_changed.connect(_show_panel)

	# Identity
	username_field.text_changed.connect(_on_username_changed)
	they_check.pressed.connect(func(): _save("identity", "pronouns", "they/them"))
	she_check.pressed.connect(func(): _save("identity", "pronouns", "she/her"))
	he_check.pressed.connect(func(): _save("identity", "pronouns", "he/him"))
	any_check.pressed.connect(func(): _save("identity", "pronouns", "any"))

	# Visual
	fullscreen_check.toggled.connect(func(v): _on_fullscreen_changed(v))
	vsync_check.toggled.connect(func(v): _on_vsync_changed(v))

	# Audio
	music_slider.value_changed.connect(func(v): _on_music_volume_changed(v))
	harsh_slider.value_changed.connect(func(v): _save("audio", "harsh_noise", v))
	harsh_test_btn.pressed.connect(_test_harsh_noise)
	subtitles_check.toggled.connect(func(v): _save("audio", "subtitles", v))
	lyrics_check.toggled.connect(func(v): _save("audio", "lyrics", v))

	# Accessibility
	no_gore_check.toggled.connect(func(v): _save("access", "no_gore", v))
	epilepsy_check.toggled.connect(func(v): _save("access", "epilepsy", v))
	text_scale_slider.value_changed.connect(_on_text_scale)

# -- Tab switching ---------------------------------------------------------------------------------------
func _show_panel(tab: int):
	identity_panel.visible = tab == 0
	visual_panel.visible   = tab == 1
	audio_panel.visible    = tab == 2
	access_panel.visible   = tab == 3

# -- Resolution ------------------------------------------------------------------------------------------
func _setup_resolution_options():
	for res in RESOLUTIONS:
		resolution_option.add_item("%d x %d" % [res.x, res.y])
	resolution_option.item_selected.connect(_on_resolution_changed)

func _get_default_resolution_index() -> int:
	var screen_size = DisplayServer.screen_get_size()
	for i in range(RESOLUTIONS.size()):
		if RESOLUTIONS[i] == screen_size:
			return i
	var best_index = 0
	for i in range(RESOLUTIONS.size()):
		if RESOLUTIONS[i].x <= screen_size.x and RESOLUTIONS[i].y <= screen_size.y:
			best_index = i
	return best_index

func _on_resolution_changed(index: int):
	var res = RESOLUTIONS[index]
	DisplayServer.window_set_size(res)
	_save("visual", "resolution", index)

# -- Fullscreen ------------------------------------------------------------------------------------------
func _on_fullscreen_changed(value: bool):
	if value:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	_save("visual", "fullscreen", value)

# -- VSync -----------------------------------------------------------------------------------------------
func _on_vsync_changed(value: bool):
	if value:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	_save("visual", "vsync", value)

# -- Streaming detection ---------------------------------------------------------------------------------
func _check_streaming_apps():
	var output = []
	OS.execute("tasklist", [], output)
	var tasks = output[0].to_lower() if output.size() > 0 else ""
	var streaming_open = "obs" in tasks or "streamlabs" in tasks or "xsplit" in tasks
	if streaming_open:
		epilepsy_check.button_pressed = true
		epilepsy_check.disabled       = true
		streaming_warning.visible     = true
		streaming_warning.text        = "Streaming app detected - epilepsy safe mode is locked on."
		_save("access", "epilepsy", true)
	else:
		epilepsy_check.disabled   = false
		streaming_warning.visible = false

# -- Handlers --------------------------------------------------------------------------------------------
func _on_username_changed(value: String):
	if value.strip_edges() == "":
		return
	SaveManager.set_value("identity", "display_name", value)

func _on_music_volume_changed(value: float):
	MusicManager.set_volume(value / 100.0)
	_save("audio", "music_volume", value)

func _test_harsh_noise():
	harsh_noise_player.volume_db = linear_to_db(harsh_slider.value / 100.0)
	harsh_noise_player.play()

func _on_text_scale(value: float):
	_save("access", "text_scale", value)
	_apply_text_scale(value)

func _apply_text_scale(value: float):
	var scaled_size = int(16 * value)
	_scale_labels(get_tree().root, scaled_size)

func _scale_labels(node: Node, size: int):
	if node is Label or node is RichTextLabel or node is Button or node is CheckBox:
		node.add_theme_font_size_override("font_size", size)
	for child in node.get_children():
		_scale_labels(child, size)

func _on_back():
	SaveManager.set_value("settings", "first_setup_done", true)
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")

# -- Save / Load -----------------------------------------------------------------------------------------
func _save(section: String, key: String, value):
	SaveManager.set_value(section, key, value)

func _load_settings():
	# Identity
	username_field.text = SaveManager.get_value("identity", "display_name", "Player")
	var saved_pronouns  = SaveManager.get_value("identity", "pronouns", "")
	match saved_pronouns:
		"they/them": they_check.button_pressed = true
		"she/her":   she_check.button_pressed  = true
		"he/him":    he_check.button_pressed   = true
		"any":       any_check.button_pressed  = true

	# Visual
	var saved_res = SaveManager.get_value("visual", "resolution", -1)
	if saved_res == -1:
		saved_res = _get_default_resolution_index()
		_save("visual", "resolution", saved_res)
	resolution_option.selected = saved_res
	_on_resolution_changed(saved_res)

	var saved_fullscreen = SaveManager.get_value("visual", "fullscreen", false)
	fullscreen_check.button_pressed = saved_fullscreen
	_on_fullscreen_changed(saved_fullscreen)

	var saved_vsync = SaveManager.get_value("visual", "vsync", true)
	vsync_check.button_pressed = saved_vsync
	_on_vsync_changed(saved_vsync)

	# Audio
	var music_vol = SaveManager.get_value("audio", "music_volume", 100.0)
	music_slider.value = music_vol
	MusicManager.set_volume(music_vol / 100.0)

	harsh_slider.value             = SaveManager.get_value("audio", "harsh_noise", 100.0)
	subtitles_check.button_pressed = SaveManager.get_value("audio", "subtitles", false)
	lyrics_check.button_pressed    = SaveManager.get_value("audio", "lyrics", false)

	# Accessibility
	no_gore_check.button_pressed  = SaveManager.get_value("access", "no_gore", false)
	epilepsy_check.button_pressed = SaveManager.get_value("access", "epilepsy", false)
	var scale                     = SaveManager.get_value("access", "text_scale", 1.0)
	text_scale_slider.value       = scale
	_apply_text_scale(scale)
