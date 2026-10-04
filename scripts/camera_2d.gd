extends Camera2D

@export_range(0.0, 5.0, 0.05)
var return_duration: float = 0.6

var normal_position: Vector2
var normal_zoom: Vector2
var normal_rotation: float

var zones: Array[Area2D] = []
var transition: Tween


func _ready() -> void:
	# Remember the camera settings you chose in the editor.
	normal_position = position
	normal_zoom = zoom
	normal_rotation = rotation

	# Allow zones to tilt the view.
	ignore_rotation = false


func enter_zone(zone: Area2D) -> void:
	if not zones.has(zone):
		zones.append(zone)

	refresh_view.call_deferred()


func exit_zone(zone: Area2D) -> void:
	zones.erase(zone)
	refresh_view.call_deferred()


func refresh_view() -> void:
	var selected: Area2D = null

	# Highest priority wins.
	# For equal priorities, the most recently entered zone wins.
	for zone in zones:
		if not is_instance_valid(zone):
			continue

		if selected == null:
			selected = zone
		elif int(zone.get("view_priority")) >= int(
			selected.get("view_priority")
		):
			selected = zone

	var target_position: Vector2 = normal_position
	var target_zoom: Vector2 = normal_zoom
	var target_rotation: float = normal_rotation
	var duration: float = return_duration

	if selected != null:
		target_position = selected.get("camera_position")
		target_zoom = Vector2.ONE * float(
			selected.get("zoom_amount")
		)
		target_rotation = deg_to_rad(
			float(selected.get("angle_degrees"))
		)
		duration = float(selected.get("transition_duration"))

	# Cancel the previous transition if another zone takes over.
	if transition != null and transition.is_valid():
		transition.kill()

	if duration <= 0.0:
		position = target_position
		zoom = target_zoom
		rotation = target_rotation
		return

	transition = create_tween().set_parallel(true)
	transition.set_trans(Tween.TRANS_SINE)
	transition.set_ease(Tween.EASE_IN_OUT)

	transition.tween_property(
		self, "position", target_position, duration
	)

	transition.tween_property(
		self, "zoom", target_zoom, duration
	)

	# Rotate using the shorter direction.
	var nearest_angle: float = rotation + wrapf(
		target_rotation - rotation,
		-PI,
		PI
	)

	transition.tween_property(
		self, "rotation", nearest_angle, duration
	)
