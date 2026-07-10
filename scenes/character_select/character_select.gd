extends Control

const NEXT_SCENE = "res://scenes/test_zone/test_zone.tscn"

# Team data
const TEAM_DATA = {
	"blue": {
		"color":      Color(0.05, 0.05, 0.5,  1.0),
		"bg_texture": "res://assets/backgrounds/bg_sonic.png"
	},
	"red": {
		"color":      Color(0.5,  0.05, 0.05, 1.0),
		"bg_texture": "res://assets/backgrounds/bg_mario.png"
	},
	"yellow": {
		"color":      Color(0.5,  0.45, 0.0,  1.0),
		"bg_texture": "res://assets/backgrounds/bg_pokemon.png"
	},
	"pink": {
		"color":      Color(0.5,  0.1,  0.35, 1.0),
		"bg_texture": "res://assets/backgrounds/bg_kirby.png"
	},
}

# Character data per team
const CHARACTERS = {
	"blue": {
		"survivors": [
			{
				"name": "SONIC",
				"description": "The Hedgehog Of The Wind specializes in Support and Overwhelming the God. His playstyle is centered around using rapid but weak stuns and using his speed to get teammates out of danger.",
				"art": "res://assets/characters/sonic.png"
			},
			{
				"name": "TAILS",
				"description": "Tails specializes in long range support. His playstyle is centered around staying back and supporting the team while he sets up defenses for himself. However his playstyle can be refined to be more centered around offense.",
				"art": "res://assets/characters/tails.png"
			},
		],
		"killers": [
			{
				"name": "THE GOD",
				"description": "2011X specializes in tunneling Survivors down one by one. His playstyle is centered around using his boundless power to whittle all Survivors down whilst picking them off one by one.",
				"art": "res://assets/characters/2011x.png"
			}
		]
	},
	"red":    { "survivors": [], "killers": [] },
	"yellow": { "survivors": [], "killers": [] },
	"pink":   { "survivors": [], "killers": [] },
}

# -- Onready ───────────────────────────────────────────────────────────────────
@onready var background        = $Background
@onready var parallax_bg       = $Background/Parallax2D
@onready var bg_texture        = $Background/Parallax2D/BGTexture
@onready var top_bar           = $Background/TopBar
@onready var bottom_bar        = $Background/BottomBar
@onready var character_name    = $Background/CharacterName
@onready var character_art     = $Background/CharacterArt
@onready var description_label = $Background/DescriptionLabel
@onready var left_arrow        = $Background/LeftArrow
@onready var right_arrow       = $Background/RightArrow
@onready var back_to_menu_btn  = $Background/TeamSelectPanel/BackToMenuButton
@onready var character_back_btn = $Background/CharacterBackButton

# Team select
@onready var team_select_panel = $Background/TeamSelectPanel
@onready var blue_team_btn     = $Background/TeamSelectPanel/TeamContainer/BlueTeamBtn
@onready var red_team_btn      = $Background/TeamSelectPanel/TeamContainer/RedTeamBtn
@onready var yellow_team_btn   = $Background/TeamSelectPanel/TeamContainer/YellowTeamBtn
@onready var pink_team_btn     = $Background/TeamSelectPanel/TeamContainer/PinkTeamBtn

var selected_team   := "blue"
var selected_role   := "survivors"
var current_index   := 0
var parallax_offset := 0.0
var can_confirm     := false

# -- Ready ─────────────────────────────────────────────────────────────────────
func _ready():
	selected_role = SaveManager.get_value("match", "role", "survivors")

	# Team buttons
	blue_team_btn.pressed.connect(func(): _select_team("blue"))
	red_team_btn.pressed.connect(func(): _select_team("red"))
	yellow_team_btn.pressed.connect(func(): _select_team("yellow"))
	pink_team_btn.pressed.connect(func(): _select_team("pink"))

	# Arrow buttons
	left_arrow.pressed.connect(_on_left)
	right_arrow.pressed.connect(_on_right)

	# Hide character UI until team is chosen
	_set_character_ui_visible(false)

	# Going Back
	back_to_menu_btn.pressed.connect(_on_back_to_menu)
	character_back_btn.pressed.connect(_on_back_to_team_select)

# -- Input ─────────────────────────────────────────────────────────────────────
func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ENTER:
				_on_confirm()
			KEY_LEFT:
				_on_left()
			KEY_RIGHT:
				_on_right()

# -- Process ───────────────────────────────────────────────────────────────────
func _process(delta):
	parallax_offset += delta * 60.0
	parallax_bg.scroll_offset = Vector2(parallax_offset, 0)

# -- Team Select ───────────────────────────────────────────────────────────────
func _select_team(team: String):
	selected_team = team
	current_index = 0

	# Hide team select, show character select
	team_select_panel.visible = false
	_set_character_ui_visible(true)

	# Save selected team
	SaveManager.set_value("match", "team", team)

	_update_display()

func _set_character_ui_visible(value: bool):
	top_bar.visible             = value
	bottom_bar.visible          = value
	character_name.visible      = value
	character_art.visible       = value
	description_label.visible   = value
	left_arrow.visible          = value
	right_arrow.visible         = value
	character_back_btn.visible  = value

# -- Navigation ────────────────────────────────────────────────────────────────
func _on_left():
	var chars = _get_current_characters()
	if chars.is_empty():
		return
	current_index = (current_index - 1 + chars.size()) % chars.size()
	_update_display()

func _on_right():
	var chars = _get_current_characters()
	if chars.is_empty():
		return
	current_index = (current_index + 1) % chars.size()
	_update_display()
	
func _on_back_to_menu():
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")

func _on_back_to_team_select():
	team_select_panel.visible = true
	_set_character_ui_visible(false)
	character_back_btn.visible = false

# -- Display ───────────────────────────────────────────────────────────────────
func _update_display():
	var data = TEAM_DATA[selected_team]

	# Update background color
	background.color = data["color"]
	top_bar.color    = Color(data["color"].r * 0.6, data["color"].g * 0.6, data["color"].b * 0.6, 0.75)
	bottom_bar.color = Color(data["color"].r * 0.6, data["color"].g * 0.6, data["color"].b * 0.6, 0.75)

	# Update background texture — hide if file doesn't exist yet
	if data["bg_texture"] != "" and ResourceLoader.exists(data["bg_texture"]):
		bg_texture.texture = load(data["bg_texture"])
		bg_texture.visible = true
	else:
		bg_texture.visible = false

	var chars = _get_current_characters()

	if chars.is_empty():
		character_name.text    = "No characters yet"
		description_label.text = "This team has no characters available yet."
		can_confirm            = false
		left_arrow.visible     = false
		right_arrow.visible    = false
		return

	var character = chars[current_index]
	character_name.text    = character["name"]
	description_label.text = character["description"]
	can_confirm            = true

	left_arrow.visible  = chars.size() > 1
	right_arrow.visible = chars.size() > 1

	# Load art if file exists — hide if not ready yet
	if character["art"] != "" and ResourceLoader.exists(character["art"]):
		character_art.texture = load(character["art"])
		character_art.visible = true
	else:
		character_art.visible = false

func _get_current_characters() -> Array:
	return CHARACTERS[selected_team][selected_role]

# -- Confirm ───────────────────────────────────────────────────────────────────
func _on_confirm():
	if not can_confirm:
		return
	var chars = _get_current_characters()
	if chars.is_empty():
		return
	var character = chars[current_index]
	SaveManager.set_value("match", "selected_character", character["name"])
	SaveManager.set_value("match", "selected_team", selected_team)
	get_tree().change_scene_to_file(NEXT_SCENE)
