@tool
extends Control

## Only the transparent interior is filled; the original artwork stays intact.
@export var frame_texture: Texture2D = preload("res://assets/health bar.png")
@export var frame_region: Rect2 = Rect2(60, 230, 1863, 316)
@export var opening_region: Rect2 = Rect2(197, 312, 1590, 150)
@export var fill_color: Color = Color("8f1828")
@export var empty_color: Color = Color("210e16")

var fill_ratio: float = 1.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func set_health(current: float, maximum: float) -> void:
	fill_ratio = clampf(current / maxf(maximum, 1.0), 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	if frame_texture == null:
		return
	var factor: Vector2 = size / frame_region.size
	var opening := Rect2(
		(opening_region.position - frame_region.position) * factor,
		opening_region.size * factor)
	draw_rect(opening, empty_color)
	var filled := Rect2(opening.position,
		Vector2(opening.size.x * fill_ratio, opening.size.y))
	draw_rect(filled, fill_color)
	draw_texture_rect_region(frame_texture, Rect2(Vector2.ZERO, size), frame_region)
