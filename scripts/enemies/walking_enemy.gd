extends CharacterBody2D

# Generic patrolling enemy driven by a single walk-cycle sprite folder
# (frame_01.png .. frame_0N.png). Used for both Macron and Trump — only the
# exported sprite folder/frame count differ between the two.

@export var sprite_folder: String = ""
@export var frame_count: int = 4
@export var walk_fps: float = 6.0
@export var patrol_min_x: float = 60.0
@export var patrol_max_x: float = 964.0

const MAX_HP := 2000
const PATROL_SPEED := 60.0
const GRAVITY := 980.0
const CONTACT_RANGE := 40.0
const CONTACT_DAMAGE := 10
const CONTACT_COOLDOWN := 1.0
const PUSH_SPEED := 400.0        # how fast an external push (e.g. Vocaloid) shoves this enemy
const PUSH_ARRIVAL_MARGIN := 4.0

var hp := MAX_HP
var _patrol_dir := 1.0
var _contact_timer := 0.0
var _push_target_x := 0.0
var _push_timer := 0.0

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	add_to_group("enemy")
	_setup_animations()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	if _push_timer > 0.0:
		_push_timer -= delta
		var dx := _push_target_x - global_position.x
		if absf(dx) > PUSH_ARRIVAL_MARGIN and _push_timer > 0.0:
			velocity.x = signf(dx) * PUSH_SPEED
		else:
			velocity.x = 0.0
			_push_timer = 0.0
	else:
		_patrol_dir = _decide_patrol_dir()
		velocity.x = PATROL_SPEED * _patrol_dir
		_sprite.flip_h = _patrol_dir < 0.0

	move_and_slide()

	if _contact_timer > 0.0:
		_contact_timer -= delta
	else:
		_check_contact_damage()


# Gradually shoves the enemy toward target_x over time (at PUSH_SPEED),
# overriding its normal AI movement until it arrives or duration runs out.
func push_toward_x(target_x: float, duration: float) -> void:
	_push_target_x = target_x
	_push_timer = duration


# Overridable: default just bounces between patrol_min_x/patrol_max_x.
# Subclasses (e.g. Trump chasing Jules) can override this to steer differently
# while still reusing gravity/movement/contact-damage above.
func _decide_patrol_dir() -> float:
	if global_position.x <= patrol_min_x:
		return 1.0
	elif global_position.x >= patrol_max_x:
		return -1.0
	return _patrol_dir


func _check_contact_damage() -> void:
	for p in get_tree().get_nodes_in_group("player"):
		var node := p as CharacterBody2D
		if node == null or not node.has_method("take_damage"):
			continue
		if global_position.distance_to(node.global_position) < CONTACT_RANGE:
			node.take_damage(CONTACT_DAMAGE)
			_contact_timer = CONTACT_COOLDOWN
			break


func _setup_animations() -> void:
	var frames := SpriteFrames.new()

	frames.add_animation("idle")
	frames.set_animation_loop("idle", true)
	frames.add_frame("idle", load("%sframe_01.png" % sprite_folder))

	frames.add_animation("walk")
	frames.set_animation_loop("walk", true)
	frames.set_animation_speed("walk", walk_fps)
	for i in range(1, frame_count + 1):
		var tex := load("%sframe_%02d.png" % [sprite_folder, i]) as Texture2D
		if tex:
			frames.add_frame("walk", tex)
		else:
			push_warning("Missing frame: %sframe_%02d.png" % [sprite_folder, i])

	_sprite.sprite_frames = frames
	_sprite.play("walk")


func take_damage(amount: int) -> void:
	hp = maxi(hp - amount, 0)
	if hp == 0:
		queue_free()
