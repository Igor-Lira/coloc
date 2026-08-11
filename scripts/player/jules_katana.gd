extends Area2D

const SPEED := 420.0  # 700 * 0.6
const LIFETIME := 1.2
const DAMAGE := 25

var velocity := Vector2.ZERO
var _life := LIFETIME


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position += velocity * delta

	_life -= delta
	if _life <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemy") and body.has_method("take_damage"):
		body.take_damage(DAMAGE)
	queue_free()
