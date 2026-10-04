extends Area2D

@export var camera: Camera2D

@export var camera_position: Vector2 = Vector2(
	480.836,
	-326.258
)

@export_range(0.1, 3.0, 0.01)
var zoom_amount: float = 0.785

@export_range(-180.0, 180.0, 1.0)
var angle_degrees: float = 0.0

@export_range(0.0, 5.0, 0.05)
var transition_duration: float = 0.6

@export var view_priority: int = 0


func _ready() -> void:
	body_entered.connect(on_body_entered)
	body_exited.connect(on_body_exited)


func on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and is_instance_valid(camera):
		camera.call("enter_zone", self)


func on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and is_instance_valid(camera):
		camera.call("exit_zone", self)
