extends CanvasLayer

var _player: Node = null
var _player_bar: ProgressBar
var _player_label: Label
var _mana_bar: ProgressBar

var _enemies: Array = []  # each: {node, bar, label, name}
var _enemy_box: VBoxContainer

var _end_overlay: ColorRect
var _end_label: Label
var _game_ended := false

# --- Countdown: starts once the story intro finishes; time's up = game over ---
const COUNTDOWN_START := 142.0  # 2:22
var _countdown_label: Label
var _countdown_active := false
var _countdown_time := COUNTDOWN_START


func _ready() -> void:
	_build_ui()
	call_deferred("_find_characters")


func _build_ui() -> void:
	# --- Jules HP (top-left) ---
	var player_box := VBoxContainer.new()
	player_box.position = Vector2(20, 16)
	add_child(player_box)

	_player_label = Label.new()
	_player_label.text = "Jules"
	_player_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	player_box.add_child(_player_label)

	_player_bar = ProgressBar.new()
	_player_bar.custom_minimum_size = Vector2(220, 22)
	_player_bar.max_value = 100
	_player_bar.value = 100
	_player_bar.show_percentage = false
	var player_fill := StyleBoxFlat.new()
	player_fill.bg_color = Color(0.15, 0.75, 0.25)
	player_fill.corner_radius_top_left = 4
	player_fill.corner_radius_top_right = 4
	player_fill.corner_radius_bottom_left = 4
	player_fill.corner_radius_bottom_right = 4
	_player_bar.add_theme_stylebox_override("fill", player_fill)
	player_box.add_child(_player_bar)

	_mana_bar = ProgressBar.new()
	_mana_bar.custom_minimum_size = Vector2(220, 12)
	_mana_bar.max_value = 100
	_mana_bar.value = 100
	_mana_bar.show_percentage = false
	var mana_fill := StyleBoxFlat.new()
	mana_fill.bg_color = Color(0.25, 0.55, 0.95)
	mana_fill.corner_radius_top_left = 4
	mana_fill.corner_radius_top_right = 4
	mana_fill.corner_radius_bottom_left = 4
	mana_fill.corner_radius_bottom_right = 4
	_mana_bar.add_theme_stylebox_override("fill", mana_fill)
	player_box.add_child(_mana_bar)

	# --- Enemy HP bars (top-right, one row per enemy found) ---
	_enemy_box = VBoxContainer.new()
	_enemy_box.position = Vector2(1040, 16)
	_enemy_box.add_theme_constant_override("separation", 14)
	add_child(_enemy_box)

	# --- Countdown (top-center, big and punchy) ---
	var countdown_panel := PanelContainer.new()
	countdown_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	countdown_panel.position = Vector2(-70, 10)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.05, 0.08, 0.75)
	panel_style.border_color = Color(1.0, 0.85, 0.2)
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(12)
	panel_style.content_margin_left = 18.0
	panel_style.content_margin_right = 18.0
	panel_style.content_margin_top = 6.0
	panel_style.content_margin_bottom = 6.0
	countdown_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(countdown_panel)

	_countdown_label = Label.new()
	_countdown_label.custom_minimum_size = Vector2(140, 0)
	_countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_countdown_label.add_theme_font_size_override("font_size", 44)
	_countdown_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	_countdown_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	_countdown_label.add_theme_constant_override("outline_size", 6)
	_countdown_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.6))
	_countdown_label.add_theme_constant_override("shadow_offset_x", 2)
	_countdown_label.add_theme_constant_override("shadow_offset_y", 3)
	_countdown_label.text = _format_time(COUNTDOWN_START)
	countdown_panel.add_child(_countdown_label)

	# --- End-game overlay (hidden until a win/loss) ---
	_end_overlay = ColorRect.new()
	_end_overlay.color = Color(0.0, 0.0, 0.0, 0.75)
	_end_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_end_overlay.visible = false
	add_child(_end_overlay)

	_end_label = Label.new()
	_end_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_end_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_end_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_end_label.add_theme_font_size_override("font_size", 56)
	_end_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	_end_overlay.add_child(_end_label)


func _find_characters() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0]
		_player_bar.max_value = _player.MAX_HP
		_mana_bar.max_value = _player.MAX_MANA

	for enemy in get_tree().get_nodes_in_group("enemy"):
		_add_enemy_bar(enemy)

	var story_intro := get_tree().current_scene.get_node_or_null("StoryIntro")
	if story_intro:
		story_intro.phase_started.connect(_on_phase_started)
	else:
		# No intro in this run (e.g. testing the level directly) — start right away.
		_countdown_active = true


func _on_phase_started() -> void:
	_countdown_active = true


func _add_enemy_bar(enemy: Node) -> void:
	var box := VBoxContainer.new()
	_enemy_box.add_child(box)

	var label := Label.new()
	label.text = enemy.name
	label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.2))
	box.add_child(label)

	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(220, 22)
	bar.max_value = enemy.MAX_HP
	bar.value = enemy.hp
	bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.75, 0.15, 0.1)
	fill.corner_radius_top_left = 4
	fill.corner_radius_top_right = 4
	fill.corner_radius_bottom_left = 4
	fill.corner_radius_bottom_right = 4
	bar.add_theme_stylebox_override("fill", fill)
	box.add_child(bar)

	_enemies.append({"node": enemy, "bar": bar, "label": label, "name": enemy.name})


func _process(delta: float) -> void:
	if _game_ended:
		return

	if _countdown_active:
		_countdown_time = maxf(_countdown_time - delta, 0.0)
		_countdown_label.text = _format_time(_countdown_time)

		if _countdown_time <= 10.0:
			# Urgent: pulse red/white in the final 10 seconds.
			var pulse := fmod(_countdown_time, 0.5) < 0.25
			_countdown_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.15) if pulse else Color(1.0, 1.0, 1.0))
		elif _countdown_time <= 30.0:
			_countdown_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.15))
		else:
			_countdown_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))

		if _countdown_time <= 0.0:
			_end_game("GAME OVER")
			return

	if is_instance_valid(_player):
		_player_bar.value = _player.hp
		_player_label.text = "Jules  %d / %d" % [_player.hp, _player.MAX_HP]
		_mana_bar.value = _player.mana

	var any_alive := false
	for e in _enemies:
		if is_instance_valid(e["node"]):
			any_alive = true
			e["bar"].value = e["node"].hp
			e["label"].text = "%s  %d / %d" % [e["name"], e["node"].hp, e["node"].MAX_HP]
		else:
			e["bar"].value = 0
			e["label"].text = "%s — defeated" % e["name"]

	if is_instance_valid(_player) and _player.hp <= 0:
		_end_game("GAME OVER")
	elif _enemies.size() > 0 and not any_alive:
		_countdown_active = false
		_end_game("CONGRATULATIONS!")


func _format_time(t: float) -> String:
	var total_sec := int(ceil(t))
	return "%d:%02d" % [total_sec / 60, total_sec % 60]


func _end_game(text: String) -> void:
	_game_ended = true
	_end_label.text = text
	_end_overlay.visible = true
	await get_tree().create_timer(2.5).timeout
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
