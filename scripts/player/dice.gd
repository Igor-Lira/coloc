extends Area2D

const SPEED := 900.0
const LIFETIME := 2.0
const DAMAGE := 15
const SPIN_SPEED := 14.0  # radians/sec, purely visual tumble

var velocity := Vector2.ZERO
var _life := LIFETIME


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position += velocity * delta
	rotation += SPIN_SPEED * delta

	_life -= delta
	if _life <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemy") and body.has_method("take_damage"):
		body.take_damage(DAMAGE)
	queue_free()
