extends CharacterBody2D

# --- Movement parameters (mirrors Florian's feel) ---
const SPEED := 154.0  # 220 * 0.7
const JUMP_VELOCITY := -580.0
const GRAVITY := 980.0

# Coyote time: lets the player jump a few frames after walking off a ledge
const COYOTE_TIME := 0.12
var _coyote_timer := 0.0

# Jump buffer: registers a jump input slightly before landing
const JUMP_BUFFER_TIME := 0.12
var _jump_buffer_timer := 0.0

# Double jump: one extra mid-air jump, refreshed on landing
const MAX_AIR_JUMPS := 1
var _air_jumps_left := MAX_AIR_JUMPS

# Dash: double-tap a direction for a brief burst of extra speed
const DASH_TAP_WINDOW := 0.3  # max seconds between taps to count as a double-tap
const DASH_SPEED_MULTIPLIER := 4.0
const DASH_DURATION := 0.12
var _left_tap_timer := 0.0
var _right_tap_timer := 0.0
var _dash_timer := 0.0
var _dash_dir := 1.0

# --- Health ---
const MAX_HP := 100
var hp := MAX_HP

const INVINCIBILITY_TIME := 1.5  # seconds of i-frames after a hit
var _invincible_timer := 0.0

# --- Basic attack: thrown katana projectile, just like Florian's dice ---
const KATANA_SCENE := preload("res://scenes/player/jules_katana.tscn")
const ATTACK_COOLDOWN := 0.45
var _attack_timer := 0.0
var _facing_dir := 1.0

# --- Mana: special can only be cast once the bar is completely full ---
const MAX_MANA := 100.0
const MANA_REGEN_TIME := 10.0  # seconds to refill from empty to full
var mana := MAX_MANA

# --- Special: Vocaloid (channel -> AOE gradient blast -> fade, invincible throughout) ---
const VOCALOID_SCENE := preload("res://scenes/player/jules_vocaloid.tscn")
var _special_timer := 0.0

# --- Special 2: volley of 6 katanas in a triangular spread (2 down, 2 middle, 2 up) ---
const VOLLEY_COOLDOWN := 2.0
const VOLLEY_MANA_COST := MAX_MANA * 0.3
const VOLLEY_ANGLES_DEG := [-20.0, -10.0, -3.0, 3.0, 10.0, 20.0]
var _volley_timer := 0.0

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	add_to_group("player")
	_setup_animations()


func _physics_process(delta: float) -> void:
	# --- Gravity ---
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# --- Mana regen ---
	mana = minf(mana + (MAX_MANA / MANA_REGEN_TIME) * delta, MAX_MANA)

	# --- Special (Vocaloid): locks Jules in place, invincible, for its full duration ---
	if _special_timer > 0.0:
		_special_timer -= delta
		if _invincible_timer > 0.0:
			_invincible_timer -= delta
		velocity.x = 0.0
		move_and_slide()
		_sprite.modulate.a = 1.0
		_sprite.play("idle")
		return

	if Input.is_action_just_pressed("special") and mana >= MAX_MANA:
		_cast_vocaloid()
		return

	# --- Coyote timer (also refreshes the double jump on solid ground) ---
	if is_on_floor():
		_coyote_timer = COYOTE_TIME
		_air_jumps_left = MAX_AIR_JUMPS
	else:
		_coyote_timer -= delta

	# --- Jump buffer timer ---
	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		_jump_buffer_timer = maxf(_jump_buffer_timer - delta, 0.0)

	# --- Jump (ground/coyote) ---
	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		velocity.y = JUMP_VELOCITY
		_coyote_timer = 0.0
		_jump_buffer_timer = 0.0
		_air_jumps_left = MAX_AIR_JUMPS
	# --- Double jump (mid-air) ---
	elif _jump_buffer_timer > 0.0 and _air_jumps_left > 0:
		velocity.y = JUMP_VELOCITY
		_jump_buffer_timer = 0.0
		_air_jumps_left -= 1

	# --- Horizontal movement ---
	var direction := Input.get_axis("move_left", "move_right")
	if _dash_timer > 0.0:
		_dash_timer -= delta
		velocity.x = _dash_dir * SPEED * DASH_SPEED_MULTIPLIER
	elif direction != 0.0:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)

	move_and_slide()

	# --- Dash (double-tap a direction) ---
	if Input.is_action_just_pressed("move_left"):
		if _left_tap_timer > 0.0:
			_try_dash(-1.0)
			_left_tap_timer = 0.0
		else:
			_left_tap_timer = DASH_TAP_WINDOW
	else:
		_left_tap_timer = maxf(_left_tap_timer - delta, 0.0)

	if Input.is_action_just_pressed("move_right"):
		if _right_tap_timer > 0.0:
			_try_dash(1.0)
			_right_tap_timer = 0.0
		else:
			_right_tap_timer = DASH_TAP_WINDOW
	else:
		_right_tap_timer = maxf(_right_tap_timer - delta, 0.0)

	# --- Invincibility timer + flash ---
	if _invincible_timer > 0.0:
		_invincible_timer -= delta
		var flash := fmod(_invincible_timer, 0.2) < 0.1
		_sprite.modulate.a = 0.25 if flash else 1.0
	else:
		_sprite.modulate.a = 1.0

	# --- Flip and animation (after move_and_slide so is_on_floor is up-to-date) ---
	_update_animation(direction)

	# --- Basic attack ---
	if _attack_timer > 0.0:
		_attack_timer -= delta
	if Input.is_action_just_pressed("attack") and _attack_timer <= 0.0:
		_perform_attack()
		_attack_timer = ATTACK_COOLDOWN

	# --- Special 2 (katana volley) ---
	if _volley_timer > 0.0:
		_volley_timer -= delta
	if Input.is_action_just_pressed("turbo") and _volley_timer <= 0.0 and mana >= VOLLEY_MANA_COST:
		mana -= VOLLEY_MANA_COST
		_throw_volley()
		_volley_timer = VOLLEY_COOLDOWN


func _update_animation(direction: float) -> void:
	if direction < 0.0:
		_sprite.flip_h = true
		_facing_dir = -1.0
	elif direction > 0.0:
		_sprite.flip_h = false
		_facing_dir = 1.0

	if _attack_timer > 0.0:
		_sprite.play("fight")
		return

	if _dash_timer > 0.0:
		_sprite.flip_h = _dash_dir < 0.0
		_sprite.play("jump")
		return

	if is_on_floor():
		if absf(direction) > 0.0:
			_sprite.play("walk")
		else:
			_sprite.play("idle")
	else:
		# No dedicated fall pose in this sprite set — reuse jump for all airtime.
		_sprite.play("jump")


# ---------------------------------------------------------------------------
# Animation setup – loads individual frame images at runtime.
# Jules' frames are 1-indexed (frame_01.png, ...), unlike Florian's frame_00.
# ---------------------------------------------------------------------------
func _setup_animations() -> void:
	var frames := SpriteFrames.new()

	_add_anim(frames, "idle",  "res://assets/characters/jules/idle/",  9, 6.0,  true)
	_add_anim(frames, "walk",  "res://assets/characters/jules/walk/",  9, 10.0, true)
	_add_anim(frames, "jump",  "res://assets/characters/jules/jump/",  6, 8.0,  false)

	# Fight frame 5 is pure effect art (the "斬" energy burst, no character in
	# it at all) — it's used as the thrown katana projectile's texture instead
	# of being part of Jules' own body animation, which would make him vanish.
	frames.add_animation("fight")
	frames.set_animation_loop("fight", false)
	frames.set_animation_speed("fight", 14.0)
	for i in [1, 2, 3, 4, 6]:
		var tex := load("res://assets/characters/jules/fight/frame_%02d.png" % i) as Texture2D
		if tex:
			frames.add_frame("fight", tex)

	_sprite.sprite_frames = frames
	_sprite.play("idle")


# ---------------------------------------------------------------------------
# Dash (double-tap speed burst)
# ---------------------------------------------------------------------------

func _try_dash(dir: float) -> void:
	_dash_timer = DASH_DURATION
	_dash_dir = dir


# ---------------------------------------------------------------------------
# Basic attack (thrown katana projectile)
# ---------------------------------------------------------------------------

func _perform_attack() -> void:
	var dir := Vector2(_facing_dir, 0.0)
	var katana := KATANA_SCENE.instantiate()
	get_tree().current_scene.add_child(katana)
	katana.global_position = global_position + dir * 30.0
	katana.velocity = dir * katana.SPEED


# ---------------------------------------------------------------------------
# Special 2 (katana volley: 6 shots in a triangular fan)
# ---------------------------------------------------------------------------

func _throw_volley() -> void:
	for angle_deg in VOLLEY_ANGLES_DEG:
		var rad := deg_to_rad(angle_deg)
		# Horizontal sign always follows facing direction; vertical sign is
		# independent of it, so "up"/"down" shots stay up/down either way.
		var dir := Vector2(_facing_dir * cos(rad), sin(rad))
		var katana := KATANA_SCENE.instantiate()
		get_tree().current_scene.add_child(katana)
		katana.global_position = global_position + dir * 30.0
		katana.velocity = dir * katana.SPEED


# ---------------------------------------------------------------------------
# Special (Vocaloid)
# ---------------------------------------------------------------------------

func _cast_vocaloid() -> void:
	mana = 0.0
	velocity.x = 0.0

	var vocaloid := VOCALOID_SCENE.instantiate()
	get_tree().current_scene.add_child(vocaloid)
	vocaloid.global_position = global_position

	_special_timer = vocaloid.TOTAL_DURATION
	_invincible_timer = maxf(_invincible_timer, vocaloid.TOTAL_DURATION)


# ---------------------------------------------------------------------------
# Health / damage
# ---------------------------------------------------------------------------

func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	if _invincible_timer > 0.0:
		return
	hp = maxi(hp - amount, 0)
	if knockback != Vector2.ZERO:
		velocity = knockback
	_invincible_timer = INVINCIBILITY_TIME


func _add_anim(frames: SpriteFrames, anim: String, path: String,
		count: int, fps: float, loop: bool) -> void:
	frames.add_animation(anim)
	frames.set_animation_loop(anim, loop)
	frames.set_animation_speed(anim, fps)
	for i in range(1, count + 1):
		var tex := load("%sframe_%02d.png" % [path, i]) as Texture2D
		if tex:
			frames.add_frame(anim, tex)
		else:
			push_warning("Missing frame: %sframe_%02d.png" % [path, i])
