extends Area2D

const DAMAGE := 20
const EXPLOSION_RADIUS := 90.0
const ARC_HEIGHT := 150.0  # how high above the straight line the arc rises
# Travel time is inversely proportional to speed (distance is fixed by the
# target), so dividing by 0.7 makes the bomb move at 0.7x its old velocity.
const DURATION := 1.0 / 0.7  # seconds to travel from start_pos to target_pos

const BLAST_SCENE := preload("res://scenes/effects/explosion_blast.tscn")

var start_pos := Vector2.ZERO
var target_pos := Vector2.ZERO
var _t := 0.0
var _exploded := false

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if _exploded:
		return

	var prev_pos := global_position

	# Elliptical lob: linear horizontally from start to target, with a
	# half-sine bump rising above the straight line and settling back to it.
	_t = minf(_t + delta / DURATION, 1.0)
	var linear := start_pos.lerp(target_pos, _t)
	var arc_offset := -sin(_t * PI) * ARC_HEIGHT
	global_position = linear + Vector2(0.0, arc_offset)

	var move_delta := global_position - prev_pos
	if move_delta.length() > 0.01:
		rotation = move_delta.angle() + PI  # bomb art points nose-left by default

	if _t >= 1.0:
		_explode()


func _on_body_entered(body: Node) -> void:
	if _exploded:
		return
	if body.is_in_group("player"):
		_explode()


func _explode() -> void:
	if _exploded:
		return
	_exploded = true

	for player in get_tree().get_nodes_in_group("player"):
		if not (player is Node2D) or not player.has_method("take_damage"):
			continue
		if global_position.distance_to((player as Node2D).global_position) <= EXPLOSION_RADIUS:
			player.take_damage(DAMAGE)

	var blast := BLAST_SCENE.instantiate()
	get_tree().current_scene.add_child(blast)
	blast.global_position = global_position
	blast.radius = EXPLOSION_RADIUS

	_sprite.visible = false
	_collision.set_deferred("disabled", true)
	await get_tree().create_timer(0.3).timeout
	queue_free()
