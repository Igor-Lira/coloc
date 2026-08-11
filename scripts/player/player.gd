extends CharacterBody2D

# --- Movement parameters (easy to tweak) ---
const SPEED := 220.0          # horizontal pixels/sec
const JUMP_VELOCITY := -580.0  # negative = upward (Godot y-axis)
const GRAVITY := 980.0         # pixels/sec²

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

# --- Basic attack (dice throw) ---
const DICE_SCENE := preload("res://scenes/player/dice.tscn")
const ATTACK_COOLDOWN := 0.4
var _attack_cooldown_timer := 0.0
var _facing_dir := 1.0

# --- Special (fareway) ---
const FAREWAY_SCENE := preload("res://scenes/player/fareway.tscn")
const FAREWAY_LANDING_OFFSET := 140.0  # how far in front of Florian it lands
const FAREWAY_FALL_LEAD := 160.0       # horizontal drift while falling, for the diagonal angle
const FAREWAY_FALL_HEIGHT := 700.0     # spawns this far above the landing point (off-screen)

# --- Mana: special can only be cast once the bar is completely full ---
const MAX_MANA := 100.0
const MANA_REGEN_TIME := 10.0  # seconds to refill from empty to full
var mana := MAX_MANA

# --- Turbo: pilot a small robot for a few seconds, invincible and faster ---
const TURBO_MANA_COST := MAX_MANA  # costs the entire mana bar
const TURBO_DURATION := 3.0
const TURBO_SPEED_MULT := 2.0
var _turbo_timer := 0.0

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _turbo_sprite: Sprite2D = $TurboSprite
@onready var _turbo_aura: Node2D = $TurboAura


func _ready() -> void:
	add_to_group("player")
	_setup_animations()


func _physics_process(delta: float) -> void:
	# --- Gravity ---
	if not is_on_floor():
		velocity.y += GRAVITY * delta

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
	var move_speed := SPEED * TURBO_SPEED_MULT if _turbo_timer > 0.0 else SPEED
	if _dash_timer > 0.0:
		_dash_timer -= delta
		velocity.x = _dash_dir * SPEED * DASH_SPEED_MULTIPLIER
	elif direction != 0.0:
		velocity.x = direction * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed)

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

	# --- Invincibility timer + flash (suppressed while turbo's own visuals are active) ---
	if _invincible_timer > 0.0:
		_invincible_timer -= delta

	if _turbo_timer > 0.0:
		_sprite.modulate.a = 1.0
	elif _invincible_timer > 0.0:
		var flash := fmod(_invincible_timer, 0.2) < 0.1
		_sprite.modulate.a = 0.25 if flash else 1.0
	else:
		_sprite.modulate.a = 1.0

	# --- Flip and animation (after move_and_slide so is_on_floor is up-to-date) ---
	_update_animation(direction)

	# --- Basic attack ---
	if _attack_cooldown_timer > 0.0:
		_attack_cooldown_timer -= delta
	if Input.is_action_just_pressed("attack") and _attack_cooldown_timer <= 0.0:
		_throw_dice()
		_attack_cooldown_timer = ATTACK_COOLDOWN

	# --- Mana regen + special ---
	mana = minf(mana + (MAX_MANA / MANA_REGEN_TIME) * delta, MAX_MANA)
	if Input.is_action_just_pressed("special") and mana >= MAX_MANA:
		_cast_special()
		mana = 0.0

	# --- Turbo ---
	if _turbo_timer > 0.0:
		_turbo_timer -= delta
		if _turbo_timer <= 0.0:
			_deactivate_turbo()
	if Input.is_action_just_pressed("turbo") and _turbo_timer <= 0.0 and mana >= TURBO_MANA_COST:
		_activate_turbo()


func _update_animation(direction: float) -> void:
	if direction < 0.0:
		_sprite.flip_h = true
		_facing_dir = -1.0
	elif direction > 0.0:
		_sprite.flip_h = false
		_facing_dir = 1.0

	if _turbo_timer > 0.0:
		_turbo_sprite.flip_h = _facing_dir > 0.0
		_sprite.play("turbo_pilot")
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

	frames.add_animation("turbo_pilot")
	frames.set_animation_loop("turbo_pilot", true)
	frames.add_frame("turbo_pilot", load("res://assets/characters/florian/fall/frame_02.png"))

	_sprite.sprite_frames = frames
	_sprite.play("idle")


# ---------------------------------------------------------------------------
# Basic attack (dice throw)
# ---------------------------------------------------------------------------

func _throw_dice() -> void:
	var dir := Vector2(_facing_dir, 0.0)
	var dice := DICE_SCENE.instantiate()
	get_tree().current_scene.add_child(dice)
	dice.global_position = global_position + dir * 40.0
	dice.velocity = dir * dice.SPEED


# ---------------------------------------------------------------------------
# Dash (double-tap speed burst)
# ---------------------------------------------------------------------------

func _try_dash(dir: float) -> void:
	_dash_timer = DASH_DURATION
	_dash_dir = dir


# ---------------------------------------------------------------------------
# Turbo (robot suit: invincible + faster for a few seconds)
# ---------------------------------------------------------------------------

func _activate_turbo() -> void:
	mana -= TURBO_MANA_COST
	_turbo_timer = TURBO_DURATION
	_invincible_timer = maxf(_invincible_timer, TURBO_DURATION)
	_turbo_sprite.visible = true
	_turbo_aura.visible = true


func _deactivate_turbo() -> void:
	_turbo_sprite.visible = false
	_turbo_aura.visible = false


# ---------------------------------------------------------------------------
# Special (fareway)
# ---------------------------------------------------------------------------

func _cast_special() -> void:
	var target := global_position + Vector2(_facing_dir * FAREWAY_LANDING_OFFSET, 0.0)
	var spawn := target + Vector2(-_facing_dir * FAREWAY_FALL_LEAD, -FAREWAY_FALL_HEIGHT)

	var fw := FAREWAY_SCENE.instantiate()
	get_tree().current_scene.add_child(fw)
	fw.global_position = spawn
	fw.target_y = target.y
	fw.velocity = (target - spawn).normalized() * fw.SPEED
	fw.rotation = fw.velocity.angle() + PI * 0.5


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
	for i in range(count):
		var tex := load("%sframe_%02d.png" % [path, i]) as Texture2D
		if tex:
			frames.add_frame(anim, tex)
		else:
			push_warning("Missing frame: %sframe_%02d.png" % [path, i])
