extends AnimatableBody2D

@export var pressure_plate: PressurePlate
@export var pressed_offset: Vector2 = Vector2(0.0, -405.0)
@export var activation_speed: float = 80.0
@export var return_speed: float = 30.0

var original_position: Vector2
var activated: bool = false


func _ready() -> void:
	original_position = global_position

	if pressure_plate == null:
		push_error("Assign Pressure Plate on MovingPlatform.")
		set_physics_process(false)
		return

	pressure_plate.pressed_changed.connect(_on_plate_changed)
	activated = pressure_plate.is_pressed


func _physics_process(delta: float) -> void:
	var target: Vector2 = original_position
	var speed: float = return_speed

	if activated:
		target = original_position + pressed_offset
		speed = activation_speed

	global_position = global_position.move_toward(
		target,
		speed * delta
	)


func _on_plate_changed(pressed: bool) -> void:
	activated = pressed
