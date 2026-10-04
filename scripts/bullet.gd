extends Node2D

@export var impact_scene: PackedScene
@export_flags_2d_physics var hit_mask: int = 3

var speed: float = 2200.0
var damage_percent: float = 8.0
var max_distance: float = 1000.0
var direction: float = 1.0
var target_group: StringName = &"enemy"

var excluded: Array[RID] = []
var travelled: float = 0.0
var finished: bool = false


func setup(
	shooter: CollisionObject2D,
	facing: float,
	bullet_speed: float,
	damage: float,
	distance: float,
	target: StringName
) -> void:
	excluded = [shooter.get_rid()]
	direction = -1.0 if facing < 0.0 else 1.0
	speed = maxf(bullet_speed, 1.0)
	damage_percent = damage
	max_distance = maxf(distance, 1.0)
	target_group = target


func _ready() -> void:
	$AnimatedSprite2D.flip_h = direction < 0.0
	$AnimatedSprite2D.play("default")


func _physics_process(delta: float) -> void:
	if finished:
		return

	var step: float = minf(
		speed * delta,
		max_distance - travelled
	)

	var end: Vector2 = global_position + Vector2(
		direction * step,
		0.0
	)

	var query := PhysicsRayQueryParameters2D.create(
		global_position,
		end,
		hit_mask,
		excluded
	)

	query.collide_with_areas = false
	query.hit_from_inside = true

	var hit: Dictionary = (
		get_world_2d().direct_space_state.intersect_ray(query)
	)

	if not hit.is_empty():
		global_position = hit["position"]

		var body: Object = hit["collider"]

		if body is Node and body.is_in_group(target_group):
			if body.has_method("take_damage_percent"):
				body.call("take_damage_percent", damage_percent)

		impact()
		return

	global_position = end
	travelled += step

	if travelled >= max_distance:
		impact()


func impact() -> void:
	if finished:
		return

	finished = true
	var audio: Node = get_tree().get_first_node_in_group("game_audio")
	if audio != null:
		audio.call("play_effect", &"bullet_impact", global_position)

	if impact_scene != null:
		var effect := impact_scene.instantiate() as Node2D
		get_tree().current_scene.add_child(effect)
		effect.global_position = global_position

	queue_free()
