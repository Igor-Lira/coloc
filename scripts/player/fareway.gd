extends Area2D

const SPEED := 480.0  # meteor-like fall
const SPIN_SPEED := 4.5  # radians/sec while airborne
const LIFETIME := 4.0
const DAMAGE := 100
const EXPLOSION_RADIUS := 240.0

const BLAST_SCENE := preload("res://scenes/effects/explosion_blast.tscn")

var velocity := Vector2.ZERO
var target_y := INF  # world y of the landing point; explodes on reaching it
var _life := LIFETIME
var _exploded := false

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if _exploded:
		return

	position += velocity * delta
	rotation += SPIN_SPEED * delta

	# Landed: check for enemies near the (live) impact point, not just a
	# direct mid-air hit. The target position was fixed at cast time, but
	# enemies keep moving during the fall, so this radius check against their
	# CURRENT position is what actually lands the hit most of the time.
	if global_position.y >= target_y:
		_explode()
		return

	_life -= delta
	if _life <= 0.0:
		_explode()


func _on_body_entered(body: Node) -> void:
	if _exploded:
		return
	if body.is_in_group("enemy"):
		_explode()


func _explode() -> void:
	if _exploded:
		return
	_exploded = true
	velocity = Vector2.ZERO

	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not (enemy is Node2D) or not enemy.has_method("take_damage"):
			continue
		if global_position.distance_to((enemy as Node2D).global_position) <= EXPLOSION_RADIUS:
			enemy.take_damage(DAMAGE)

	var blast := BLAST_SCENE.instantiate()
	get_tree().current_scene.add_child(blast)
	blast.global_position = global_position
	blast.radius = EXPLOSION_RADIUS

	_sprite.visible = false
	_collision.set_deferred("disabled", true)
	await get_tree().create_timer(0.3).timeout
	queue_free()
