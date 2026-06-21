extends Control

@onready var button_list       = $ButtonList
@onready var play_btn          = $ButtonList/PlayButton
@onready var server_list_btn   = $ButtonList/ServerListButton
@onready var tutorials_btn     = $ButtonList/TutorialsButton
@onready var information_btn   = $ButtonList/InformationButton
@onready var settings_btn      = $ButtonList/SettingsButton
@onready var exit_btn          = $ButtonList/ExitButton
@onready var tutorials_panel   = $TutorialsPanel
@onready var information_panel = $InformationPanel
@onready var tutorials_back    = $TutorialsPanel/BackButton
@onready var information_back  = $InformationPanel/BackButton

func _ready():
	print("button_list: ", button_list)
	print("play_btn: ", play_btn)
	print("server_list_btn: ", server_list_btn)
	print("tutorials_btn: ", tutorials_btn)
	print("information_btn: ", information_btn)
	print("settings_btn: ", settings_btn)
	print("exit_btn: ", exit_btn)
	print("tutorials_panel: ", tutorials_panel)
	print("information_panel: ", information_panel)

	tutorials_panel.visible = false
	information_panel.visible = false

	play_btn.pressed.connect(_on_play)
	server_list_btn.pressed.connect(_on_server_list)
	tutorials_btn.pressed.connect(_on_tutorials)
	information_btn.pressed.connect(_on_information)
	settings_btn.pressed.connect(_on_settings)
	exit_btn.pressed.connect(_on_exit)
	tutorials_back.pressed.connect(_on_back)
	information_back.pressed.connect(_on_back)

func _on_play():
	get_tree().change_scene_to_file("res://scenes/server_list/server_list.tscn")

func _on_server_list():
	get_tree().change_scene_to_file("res://scenes/server_list/server_list.tscn")

func _on_tutorials():
	_show_panel("tutorials")

func _on_information():
	_show_panel("information")

func _on_settings():
	get_tree().change_scene_to_file("res://scenes/settings/settings.tscn")

func _on_exit():
	get_tree().quit()

func _on_back():
	_show_panel("menu")

func _show_panel(panel: String):
	button_list.visible       = false
	tutorials_panel.visible   = false
	information_panel.visible = false
	match panel:
		"menu":
			button_list.visible       = true
		"tutorials":
			tutorials_panel.visible   = true
		"information":
			information_panel.visible = true
