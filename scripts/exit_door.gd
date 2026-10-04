extends Area2D

signal access_denied
signal opened

@export var required_keys: int = 2
var is_opening: bool = false
var is_open: bool = false
var visitor: Node2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	sprite.stop()
	sprite.animation = &"default"
	sprite.set_frame_and_progress(0, 0.0)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	visitor = body
	if not body.is_connected("keys_changed", _on_keys_changed):
		body.connect("keys_changed", _on_keys_changed)
	try_open.call_deferred()


func _on_body_exited(body: Node2D) -> void:
	if body == visitor:
		if body.is_connected("keys_changed", _on_keys_changed):
			body.disconnect("keys_changed", _on_keys_changed)
		visitor = null


func _on_keys_changed(_count: int) -> void:
	# Recheck after Area2D overlap data has been updated.
	try_open.call_deferred()


func try_open() -> void:
	if is_opening or is_open or not is_instance_valid(visitor):
		return
	if visitor.get("is_dying") == true or not overlaps_body(visitor):
		return
	var keys: Array = visitor.get("collected_keys")
	if keys.size() < required_keys:
		access_denied.emit()
		return
	is_opening = true
	sprite.play("default")
	sprite.set_frame_and_progress(0, 0.0)
	await sprite.animation_finished
	sprite.pause()
	is_open = true
	is_opening = false
	opened.emit()
