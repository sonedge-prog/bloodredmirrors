extends Control

@onready var button_list       = $Background/ButtonList
@onready var play_btn          = $Background/ButtonList/PlayButton
@onready var server_list_btn   = $Background/ButtonList/ServerListButton
@onready var tutorials_btn     = $Background/ButtonList/TutorialsButton
@onready var information_btn   = $Background/ButtonList/InformationButton
@onready var settings_btn      = $Background/ButtonList/SettingsButton
@onready var exit_btn          = $Background/ButtonList/ExitButton

@onready var tutorials_panel   = $TutorialsPanel
@onready var information_panel = $InformationPanel

@onready var tutorials_back    = $TutorialsPanel/BackButton
@onready var information_back  = $InformationPanel/BackButton

func _ready():
	# Hide panels at start
	tutorials_panel.visible   = false
	information_panel.visible = false

	# Main menu buttons
	play_btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/server_list/server_list.tscn"))
	server_list_btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/server_list/server_list.tscn"))
	tutorials_btn.pressed.connect(func():
		_show_panel("tutorials"))
	information_btn.pressed.connect(func():
		_show_panel("information"))
	settings_btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/settings/settings.tscn"))
	exit_btn.pressed.connect(func():
		get_tree().quit())

	# Back buttons
	tutorials_back.pressed.connect(func():
		_show_panel("menu"))
	information_back.pressed.connect(func():
		_show_panel("menu"))

func _show_panel(panel: String):
	# Hide everything first
	button_list.visible       = false
	tutorials_panel.visible   = false
	information_panel.visible = false

	# Show what we need
	match panel:
		"menu":
			button_list.visible     = true
		"tutorials":
			tutorials_panel.visible = true
		"information":
			information_panel.visible = true
