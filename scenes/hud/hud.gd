extends CanvasLayer

const TEAM_COLORS = {
	"blue":   Color(0.05, 0.05, 0.5,  1.0),
	"red":    Color(0.5,  0.05, 0.05, 1.0),
	"yellow": Color(0.5,  0.45, 0.0,  1.0),
	"pink":   Color(0.5,  0.1,  0.35, 1.0),
}

@onready var player_portrait_frame = $Root/PlayerStatus/PlayerPortraitFrame
@onready var player_name_label     = $Root/PlayerStatus/PlayerNameLabel
@onready var health_bar            = $Root/PlayerStatus/HealthBar
@onready var health_label          = $Root/PlayerStatus/HealthBar/HealthLabel
@onready var teammates_container   = $Root/TeammatesContainer
@onready var ability_slots = [
	$Root/AbilitiesPanel/AbilitySlots/Ability1Slot,
	$Root/AbilitiesPanel/AbilitySlots/Ability2Slot,
	$Root/AbilitiesPanel/AbilitySlots/Ability3Slot,
	$Root/AbilitiesPanel/AbilitySlots/Ability4Slot,
	$Root/AbilitiesPanel/AbilitySlots/Ability5Slot,
]
@onready var task_list    = $Root/TasksPanel/TaskList
@onready var task_manager = $TaskManager

var player_ref: Node = null

func _ready():
	add_to_group("hud")

	var team      = SaveManager.get_value("match", "selected_team", "blue")
	var character = SaveManager.get_value("match", "selected_character", "SONIC")
	player_name_label.text = character
	_apply_team_color(team)

	# Find the player and hook into their health signal instead of owning health data
	player_ref = get_tree().get_first_node_in_group("player")
	if player_ref:
		player_ref.health_changed.connect(_on_player_health_changed)
	else:
		push_warning("HUD: No player found in group 'player'")

	task_manager.task_completed.connect(_on_task_completed)
	task_manager.task_progress.connect(_on_task_progress)
	task_manager.all_tasks_completed.connect(_on_all_tasks_completed)

	# Example tasks for the test zone
	task_manager.add_progress_task("light_torches", "Light Torches", 4)
	task_manager.add_task("repair_plane", "Repair Plane")

	_refresh_task_display()

func _apply_team_color(team: String):
	if TEAM_COLORS.has(team):
		player_portrait_frame.color = TEAM_COLORS[team]

# -- Health display (driven entirely by the player's signal now) --------------------------------------------
func _on_player_health_changed(current: float, max: float):
	health_bar.max_value = max
	health_bar.value     = current
	health_label.text    = "%d / %d" % [int(current), int(max)]

func add_teammate(character_name: String, team: String):
	var entry = HBoxContainer.new()
	var portrait = ColorRect.new()
	portrait.custom_minimum_size = Vector2(50, 50)
	if TEAM_COLORS.has(team):
		portrait.color = TEAM_COLORS[team]
	entry.add_child(portrait)

	var label = Label.new()
	label.text = character_name
	label.custom_minimum_size = Vector2(150, 50)
	entry.add_child(label)

	teammates_container.add_child(entry)

# -- Abilities -------------------------------------------------------------------------------------------
func start_ability_cooldown(slot_index: int, duration: float):
	if slot_index < 0 or slot_index >= ability_slots.size():
		return
	var slot = ability_slots[slot_index]
	var overlay = slot.get_node("CooldownOverlay")
	overlay.visible = true
	overlay.modulate.a = 0.7

	var tween = create_tween()
	tween.tween_property(overlay, "modulate:a", 0.0, duration)
	tween.tween_callback(func():
		overlay.visible = false
		overlay.modulate.a = 0.7)

func set_ability_icon(slot_index: int, texture: Texture2D):
	if slot_index < 0 or slot_index >= ability_slots.size():
		return
	ability_slots[slot_index].texture = texture

# -- Tasks -------------------------------------------------------------------------------------------------
func _refresh_task_display():
	for child in task_list.get_children():
		child.queue_free()
	for line in task_manager.get_display_lines():
		var label = Label.new()
		label.text = line
		task_list.add_child(label)

func _on_task_completed(task_id: String):
	_refresh_task_display()

func _on_task_progress(task_id, current, total):
	_refresh_task_display()

func _on_all_tasks_completed():
	print("All tasks completed!")
