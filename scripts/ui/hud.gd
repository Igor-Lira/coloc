extends CanvasLayer

var _florian: Node = null
var _carl: Node = null
var _carl_found := false

var _florian_bar: ProgressBar
var _florian_label: Label
var _mana_bar: ProgressBar
var _carl_bar: ProgressBar
var _carl_label: Label

var _end_overlay: ColorRect
var _end_label: Label
var _game_ended := false


func _ready() -> void:
	_build_ui()
	call_deferred("_find_characters")


func _build_ui() -> void:
	# --- Florian HP (top-left) ---
	var fl_box := VBoxContainer.new()
	fl_box.position = Vector2(20, 16)
	add_child(fl_box)

	_florian_label = Label.new()
	_florian_label.text = "Florian"
	_florian_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	fl_box.add_child(_florian_label)

	_florian_bar = ProgressBar.new()
	_florian_bar.custom_minimum_size = Vector2(220, 22)
	_florian_bar.max_value = 100
	_florian_bar.value = 100
	_florian_bar.show_percentage = false
	var fl_fill := StyleBoxFlat.new()
	fl_fill.bg_color = Color(0.15, 0.75, 0.25)
	fl_fill.corner_radius_top_left = 4
	fl_fill.corner_radius_top_right = 4
	fl_fill.corner_radius_bottom_left = 4
	fl_fill.corner_radius_bottom_right = 4
	_florian_bar.add_theme_stylebox_override("fill", fl_fill)
	fl_box.add_child(_florian_bar)

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
	fl_box.add_child(_mana_bar)

	# --- Carl HP (top-right) ---
	var carl_box := VBoxContainer.new()
	carl_box.position = Vector2(1040, 16)
	add_child(carl_box)

	_carl_label = Label.new()
	_carl_label.text = "Carl"
	_carl_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.2))
	carl_box.add_child(_carl_label)

	_carl_bar = ProgressBar.new()
	_carl_bar.custom_minimum_size = Vector2(220, 22)
	_carl_bar.max_value = 200
	_carl_bar.value = 200
	_carl_bar.show_percentage = false
	var carl_fill := StyleBoxFlat.new()
	carl_fill.bg_color = Color(0.75, 0.15, 0.1)
	carl_fill.corner_radius_top_left = 4
	carl_fill.corner_radius_top_right = 4
	carl_fill.corner_radius_bottom_left = 4
	carl_fill.corner_radius_bottom_right = 4
	_carl_bar.add_theme_stylebox_override("fill", carl_fill)
	carl_box.add_child(_carl_bar)

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
	var enemies := get_tree().get_nodes_in_group("enemy")
	if players.size() > 0:
		_florian = players[0]
		_florian_bar.max_value = _florian.MAX_HP
		_mana_bar.max_value = _florian.MAX_MANA
	if enemies.size() > 0:
		_carl = enemies[0]
		_carl_bar.max_value = _carl.MAX_HP
		_carl_found = true


func _process(_delta: float) -> void:
	if _game_ended:
		return

	if is_instance_valid(_florian):
		_florian_bar.value = _florian.hp
		_florian_label.text = "Florian  %d / %d" % [_florian.hp, _florian.MAX_HP]
		_mana_bar.value = _florian.mana

	if is_instance_valid(_carl):
		_carl_bar.value = _carl.hp
		_carl_label.text = "Carl  %d / %d" % [_carl.hp, _carl.MAX_HP]
	else:
		_carl_bar.value = 0
		_carl_label.text = "Carl — WHAT"

	if is_instance_valid(_florian) and _florian.hp <= 0:
		_end_game("GAME OVER")
	elif _carl_found and not is_instance_valid(_carl):
		_end_game("CONGRATULATIONS!")


func _end_game(text: String) -> void:
	_game_ended = true
	_end_label.text = text
	_end_overlay.visible = true
	await get_tree().create_timer(2.5).timeout
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
