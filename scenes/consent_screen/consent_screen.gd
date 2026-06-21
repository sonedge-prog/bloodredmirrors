extends Control

const NEXT_SCENE = "res://scenes/intro_screen/intro_screen.tscn"

# Step 1 nodes
@onready var step1_panel       = $Background/Step1Panel
@onready var preview_label     = $Background/Step1Panel/PreviewLabel
@onready var accept_btn        = $Background/Step1Panel/AcceptButton
@onready var redact_btn        = $Background/Step1Panel/RedactButton
@onready var custom_btn        = $Background/Step1Panel/CustomButton
@onready var custom_container  = $Background/Step1Panel/CustomContainer
@onready var custom_field      = $Background/Step1Panel/CustomContainer/CustomField
@onready var custom_confirm    = $Background/Step1Panel/CustomContainer/ConfirmButton

# Step 2 nodes
@onready var step2_panel       = $Background/Step2Panel
@onready var username_field    = $Background/Step2Panel/UsernameField
@onready var username_confirm  = $Background/Step2Panel/ConfirmButton

var pc_name := ""

func _ready():
	pc_name = _get_pc_name()
	preview_label.text = "Your name would appear as:  %s" % pc_name

	step1_panel.visible = true
	step2_panel.visible = false
	custom_container.visible = false

	accept_btn.pressed.connect(_on_accept_pc)
	redact_btn.pressed.connect(_on_redact)
	custom_btn.pressed.connect(_on_custom)
	custom_confirm.pressed.connect(_on_custom_confirm)
	username_confirm.pressed.connect(_on_username_confirm)

# ── PC Name ────────────────────────────────────────────────────────────────────
func _get_pc_name() -> String:
	var name = ""
	if OS.get_name() == "Windows":
		name = OS.get_environment("USERNAME")
	else:
		name = OS.get_environment("USER")
	if name.strip_edges() == "":
		name = "Player"
	return name

# ── Step 1 Choices ─────────────────────────────────────────────────────────────
func _on_accept_pc():
	SaveManager.set_value("identity", "horror_name", pc_name)
	SaveManager.set_value("identity", "use_pc_name", true)
	_go_to_step2()

func _on_redact():
	SaveManager.set_value("identity", "horror_name", "████████")
	SaveManager.set_value("identity", "use_pc_name", false)
	_go_to_step2()

func _on_custom():
	custom_container.visible = true
	accept_btn.visible = false
	redact_btn.visible = false
	custom_btn.visible = false

func _on_custom_confirm():
	var chosen = custom_field.text.strip_edges()
	if chosen == "":
		chosen = "████████"
	SaveManager.set_value("identity", "horror_name", chosen)
	SaveManager.set_value("identity", "use_pc_name", false)
	_go_to_step2()

# ── Step 2 ─────────────────────────────────────────────────────────────────────
func _go_to_step2():
	step1_panel.visible = false
	step2_panel.visible = true

func _on_username_confirm():
	var username = username_field.text.strip_edges()
	if username == "":
		username = "Player"
	SaveManager.set_value("identity", "display_name", username)
	_finish()

# ── Finish ─────────────────────────────────────────────────────────────────────
func _finish():
	SaveManager.set_value("identity", "consent_done", true)
	get_tree().change_scene_to_file(NEXT_SCENE)
