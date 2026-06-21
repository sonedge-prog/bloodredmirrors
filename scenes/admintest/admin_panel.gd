extends CanvasLayer

const GIVEABLE_ITEMS = ["MegaMushroom", "StarPower", "FireFlower"]

# Fake players for testing
const FAKE_PLAYERS = [
	{ "id": 1, "name": "Alice" },
	{ "id": 2, "name": "Bob" },
	{ "id": 3, "name": "Charlie" },
	{ "id": 4, "name": "Diana" },
]

var panel_open := false
var selected_player = null

@onready var toggle_button    = $ToggleButton
@onready var main_frame       = $MainFrame
@onready var scroll_container = $MainFrame/PlayerListFrame/ScrollContainer
@onready var hint_label       = $MainFrame/ItemPanel/HintLabel
@onready var selected_label   = $MainFrame/ItemPanel/SelectedLabel
@onready var item_list        = $MainFrame/ItemPanel/ItemList

func _ready():
	main_frame.visible = false
	toggle_button.pressed.connect(_toggle_panel)

	# Populate with fake players
	for player in FAKE_PLAYERS:
		_add_player_to_list(player)

	# Build item buttons
	_build_item_panel()

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SEMICOLON:
			_toggle_panel()

# ── Toggle ─────────────────────────────────────────────────────────────────────

func _toggle_panel():
	panel_open = not panel_open
	main_frame.visible = panel_open

# ── Player List ────────────────────────────────────────────────────────────────

func _add_player_to_list(player: Dictionary):
	var btn = Button.new()
	btn.name = str(player["id"])
	btn.text = player["name"]
	btn.custom_minimum_size = Vector2(0, 36)

	btn.pressed.connect(func(): _select_player(player, btn))
	scroll_container.add_child(btn)

func _select_player(player: Dictionary, btn: Button):
	selected_player = player

	# Reset all buttons
	for child in scroll_container.get_children():
		if child is Button:
			child.modulate = Color.WHITE

	# Highlight selected
	btn.modulate = Color(0.3, 0.7, 1.0)

	selected_label.text = "Target:  " + player["name"]
	hint_label.visible = false

# ── Item Panel ─────────────────────────────────────────────────────────────────

func _build_item_panel():
	for item_name in GIVEABLE_ITEMS:
		var btn = Button.new()
		btn.text = item_name
		btn.custom_minimum_size = Vector2(0, 36)
		btn.pressed.connect(func(): _give_item(item_name, btn))
		item_list.add_child(btn)

func _give_item(item_name: String, btn: Button):
	if selected_player == null:
		# Flash red — no player selected
		btn.modulate = Color(1.0, 0.2, 0.2)
		await get_tree().create_timer(0.4).timeout
		btn.modulate = Color.WHITE
		return

	# Simulate giving item
	print("[ADMIN] Gave '%s' to %s" % [item_name, selected_player["name"]])

	# Flash green as confirmation
	btn.modulate = Color(0.2, 1.0, 0.4)
	await get_tree().create_timer(0.3).timeout
	btn.modulate = Color.WHITE
