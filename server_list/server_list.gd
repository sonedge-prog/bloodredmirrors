extends Control

@onready var host_btn         = $Background/BottomButtons/HostButton
@onready var join_private_btn = $Background/BottomButtons/JoinPrivateButton

# Fake servers for testing
const FAKE_SERVERS = [
	{ "name": "Server #1", "players": "3/8", "type": "Public" },
	{ "name": "Server #2", "players": "1/8", "type": "Public" },
	{ "name": "Server #3", "players": "7/8", "type": "Public" },
]

@onready var server_container = $Background/ServerScroll/ServerContainer

func _ready():
	# Populate fake server list
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

func _on_host():
	# Will open host dialog later
	print("Host a server clicked")

func _on_join_private():
	# Will open join dialog later
	print("Join private server clicked")
