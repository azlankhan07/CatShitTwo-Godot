extends Node2D

@export var player_path: NodePath = NodePath("../Player")
@export var door_path: NodePath = NodePath("../Door")
@export var enemy_paths: Array[NodePath] = [NodePath("../Enemy"), NodePath("../Enemy2")]
@export var spawn_duration: float = 4.0
@export var acid_duration: float = 5.0
@export var popup_duration: float = 2.5

var defeated: Array[int] = []
var acid_shown: bool = false
var acid_pending: bool = false
var victory: bool = false
var popup_generation: int = 0
var player: Node2D

@onready var health_bar: Control = $HUD/Screen/HealthBar
@onready var health_text: Label = $HUD/Screen/HealthValue
@onready var key_text: Label = $HUD/Screen/Keys
@onready var popup: PanelContainer = $HUD/Screen/Popup
@onready var victory_panel: Control = $HUD/Screen/Victory


func _ready() -> void:
	player = get_node(player_path) as Node2D
	# This reference lies outside the reusable LevelUI scene, so bind it at runtime.
	$AcidCameraZone.camera = player.get_node("Camera2D") as Camera2D
	player.connect("health_changed", _on_health_changed)
	player.connect("keys_changed", _on_keys_changed)
	_on_health_changed(float(player.get("health")), 100.0)
	_on_keys_changed((player.get("collected_keys") as Array).size())
	for path in enemy_paths:
		var enemy: Node = get_node(path)
		enemy.connect("died", _on_enemy_died.bind(enemy.get_instance_id()))
	var door: Node = get_node(door_path)
	door.connect("access_denied", _show_locked_popup)
	door.connect("opened", _on_door_opened)
	$AcidApproach.body_entered.connect(_on_acid_approach)
	$AcidApproach.body_exited.connect(_on_acid_left)
	$WorldMessages/Spawn.show_for(spawn_duration)


func _on_health_changed(current: float, maximum: float) -> void:
	health_bar.call("set_health", current, maximum)
	health_text.text = "%d / %d" % [ceili(current), int(maximum)]


func _on_keys_changed(count: int) -> void:
	key_text.text = "KEYS %d / 2" % count
	if count >= 2:
		popup.hide()


func _on_enemy_died(id: int) -> void:
	if defeated.has(id):
		return
	defeated.append(id)
	if defeated.size() == enemy_paths.size():
		$WorldMessages/Exit.show_for(0.0)


func _on_acid_approach(body: Node2D) -> void:
	if acid_shown or not body.is_in_group("player"):
		return
	acid_pending = true


func _on_acid_left(body: Node2D) -> void:
	if body.is_in_group("player"):
		acid_pending = false


func _process(_delta: float) -> void:
	if not acid_pending or acid_shown:
		return
	var label: Label = $WorldMessages/Acid
	var screen_rect: Rect2 = label.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, label.size)
	var safe_view: Rect2 = get_viewport_rect().grow(-24.0)
	# Reserve the top strip for the health bar.
	safe_view.position.y = 120.0
	safe_view.size.y = get_viewport_rect().size.y - 144.0
	if safe_view.encloses(screen_rect):
		acid_shown = true
		acid_pending = false
		label.call("show_for", acid_duration)


func _show_locked_popup() -> void:
	if victory:
		return
	popup_generation += 1
	var current: int = popup_generation
	popup.show()
	await get_tree().create_timer(popup_duration, false).timeout
	if current == popup_generation:
		popup.hide()


func _on_door_opened() -> void:
	if victory or player.get("is_dying") == true:
		return
	victory = true
	popup.hide()
	victory_panel.show()
	# Freeze gameplay only after the complete opening animation.
	# This HUD continues processing so its restart button remains usable.
	get_tree().paused = true


func _on_play_again_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
