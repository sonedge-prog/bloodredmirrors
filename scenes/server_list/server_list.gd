extends Control

@onready var host_btn         = $Background/BottomButtons/HostButton
@onready var join_private_btn = $Background/BottomButtons/JoinButton
@onready var server_container = $Background/ServerScroll/ServerContainer
@onready var back_btn = $Background/BackButton

const FAKE_SERVERS = [
	{ "name": "Server #1", "players": "3/8", "type": "Public" },
	{ "name": "Server #2", "players": "1/8", "type": "Public" },
	{ "name": "Server #3", "players": "7/8", "type": "Public" },
]

func _ready():
	for server in FAKE_SERVERS:
		var label = Label.new()
		label.text = "%s | %s players | %s" % [
			server["name"],
			server["players"],
			server["type"]
		]
		server_container.add_child(label)

	host_btn.pressed.connect(_on_host)
	join_private_btn.pressed.connect(_on_join_private)
	back_btn.pressed.connect(_on_back)

func _on_host():
	print("Host a server clicked")

func _on_join_private():
	print("Join private server clicked")

func _on_back():
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
