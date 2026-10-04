class_name PressurePlate
extends Area2D

signal pressed_changed(pressed: bool)

var is_pressed: bool = false


func _physics_process(_delta: float) -> void:
	var occupied: bool = false

	for body in get_overlapping_bodies():
		if body.is_in_group("pressure_weights"):
			occupied = true
			break

	if occupied != is_pressed:
		is_pressed = occupied
		pressed_changed.emit(is_pressed)
