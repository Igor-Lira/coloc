extends CharacterBody2D

# --- Movement parameters (easy to tweak) ---
const SPEED := 220.0          # horizontal pixels/sec
const JUMP_VELOCITY := -480.0  # negative = upward (Godot y-axis)
const GRAVITY := 980.0         # pixels/sec²

# Coyote time: lets the player jump a few frames after walking off a ledge
const COYOTE_TIME := 0.12
var _coyote_timer := 0.0

# Jump buffer: registers a jump input slightly before landing
const JUMP_BUFFER_TIME := 0.12
var _jump_buffer_timer := 0.0

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	_setup_animations()


func _physics_process(delta: float) -> void:
	# --- Gravity ---
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# --- Coyote timer ---
	if is_on_floor():
		_coyote_timer = COYOTE_TIME
	else:
		_coyote_timer -= delta

	# --- Jump buffer timer ---
	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		_jump_buffer_timer = maxf(_jump_buffer_timer - delta, 0.0)

	# --- Jump ---
	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		velocity.y = JUMP_VELOCITY
		_coyote_timer = 0.0
		_jump_buffer_timer = 0.0

	# --- Horizontal movement ---
	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)

	move_and_slide()

	# --- Flip and animation (after move_and_slide so is_on_floor is up-to-date) ---
	_update_animation(direction)


func _update_animation(direction: float) -> void:
	if direction < 0.0:
		_sprite.flip_h = true
	elif direction > 0.0:
		_sprite.flip_h = false

	if is_on_floor():
		if absf(direction) > 0.0:
			_sprite.play("walk")
		else:
			_sprite.play("idle")
	else:
		if velocity.y < 0.0:
			_sprite.play("jump")
		else:
			_sprite.play("fall")


# ---------------------------------------------------------------------------
# Animation setup – loads individual frame images at runtime.
# To swap sprites: replace the PNG files in assets/characters/florian/{anim}/
# To add animations: call _add_anim() here and add the matching PNG files.
# ---------------------------------------------------------------------------
func _setup_animations() -> void:
	var frames := SpriteFrames.new()

	_add_anim(frames, "idle",  "res://assets/characters/florian/idle/",  4, 6.0,  true)
	_add_anim(frames, "walk",  "res://assets/characters/florian/walk/",  5, 10.0, true)
	_add_anim(frames, "run",   "res://assets/characters/florian/run/",   5, 14.0, true)
	_add_anim(frames, "jump",  "res://assets/characters/florian/jump/",  4, 8.0,  false)
	_add_anim(frames, "fall",  "res://assets/characters/florian/fall/",  3, 8.0,  true)

	_sprite.sprite_frames = frames
	_sprite.play("idle")


func _add_anim(frames: SpriteFrames, anim: String, path: String,
		count: int, fps: float, loop: bool) -> void:
	frames.add_animation(anim)
	frames.set_animation_loop(anim, loop)
	frames.set_animation_speed(anim, fps)
	for i in range(count):
		var tex := load("%sframe_%02d.png" % [path, i]) as Texture2D
		if tex:
			frames.add_frame(anim, tex)
		else:
			push_warning("Missing frame: %sframe_%02d.png" % [path, i])
