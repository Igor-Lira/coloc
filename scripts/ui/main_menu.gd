extends CanvasLayer

const DICE_TEX := "res://assets/characters/florian/dice.png"
const FAREWAY_TEX := "res://assets/characters/florian/fareway.jpeg"
const TURBO_TEX := "res://assets/characters/florian/turbo.png"
const FLORIAN_IDLE_TEX := "res://assets/characters/florian/idle/frame_00.png"

const GOLD := Color(1.0, 0.82, 0.25)
const CYAN := Color(0.35, 0.85, 1.0)

var _menu_box: VBoxContainer
var _characters_box: VBoxContainer


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.07, 0.1, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_menu_box = _build_main_menu()
	center.add_child(_menu_box)

	_characters_box = _build_characters_screen()
	_characters_box.visible = false
	center.add_child(_characters_box)


# ---------------------------------------------------------------------------
# Look & feel helpers ("game alike" typography + juicy buttons)
# ---------------------------------------------------------------------------

func _punch_label(label: Label, size: int, color: Color) -> void:
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	label.add_theme_constant_override("outline_size", maxi(4, size / 8))
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.6))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 3)


func _style_button(button: Button, accent: Color) -> void:
	button.add_theme_font_size_override("font_size", 20)

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.14, 0.14, 0.2, 1.0)
	normal.border_color = accent
	normal.set_border_width_all(3)
	normal.set_corner_radius_all(10)
	normal.content_margin_left = 10.0
	normal.content_margin_right = 10.0

	var hover := normal.duplicate()
	hover.bg_color = accent.darkened(0.2)

	var pressed := normal.duplicate()
	pressed.bg_color = accent.darkened(0.5)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", Color(1, 1, 1))
	button.add_theme_color_override("font_hover_color", Color(1, 1, 1))


func _add_hover_bounce(control: Control, base_scale: float = 1.0) -> void:
	control.pivot_offset = control.custom_minimum_size * 0.5
	control.mouse_filter = Control.MOUSE_FILTER_STOP
	control.mouse_entered.connect(func() -> void:
		var tw := create_tween()
		tw.tween_property(control, "scale", Vector2.ONE * (base_scale * 1.06), 0.12) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	control.mouse_exited.connect(func() -> void:
		var tw := create_tween()
		tw.tween_property(control, "scale", Vector2.ONE * base_scale, 0.12)
	)


func _make_icon(path: String, box_size: Vector2) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = load(path)
	icon.custom_minimum_size = box_size
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return icon


# ---------------------------------------------------------------------------
# Main menu
# ---------------------------------------------------------------------------

func _build_main_menu() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 24)
	box.alignment = BoxContainer.ALIGNMENT_CENTER

	var title := Label.new()
	title.text = "Coloc Game"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_punch_label(title, 52, GOLD)
	box.add_child(title)

	var start_button := Button.new()
	start_button.text = "▶  Start Game"
	start_button.custom_minimum_size = Vector2(240, 56)
	start_button.pressed.connect(_on_start_pressed)
	_style_button(start_button, Color(0.2, 0.75, 0.35))
	box.add_child(start_button)

	var characters_button := Button.new()
	characters_button.text = "★  Characters"
	characters_button.custom_minimum_size = Vector2(240, 56)
	characters_button.pressed.connect(_on_characters_pressed)
	_style_button(characters_button, CYAN)
	box.add_child(characters_button)

	return box


# ---------------------------------------------------------------------------
# Characters screen
# ---------------------------------------------------------------------------

func _build_characters_screen() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 24)
	box.alignment = BoxContainer.ALIGNMENT_CENTER

	var title := Label.new()
	title.text = "Qui va sauver la coloc ?"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_punch_label(title, 34, Color(1, 1, 1))
	box.add_child(title)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 28)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(row)

	row.add_child(_build_florian_card())
	row.add_child(_build_coming_soon_card("Igor", "🔧 bricole des trucs, on sait pas trop quoi"))
	row.add_child(_build_coming_soon_card("Jules", "🛋️ toujours sur le canapé, jamais prêt"))

	var back_button := Button.new()
	back_button.text = "←  Back"
	back_button.custom_minimum_size = Vector2(160, 48)
	back_button.pressed.connect(_on_back_pressed)
	_style_button(back_button, Color(0.8, 0.3, 0.3))
	box.add_child(back_button)

	return box


func _build_florian_card() -> PanelContainer:
	var card_size := Vector2(320, 430)
	var panel := _make_card_panel(card_size, GOLD)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)

	var name_label := Label.new()
	name_label.text = "Florian"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_punch_label(name_label, 24, GOLD)
	box.add_child(name_label)

	var portrait := _make_icon(FLORIAN_IDLE_TEX, Vector2(70, 112))
	var portrait_row := CenterContainer.new()
	portrait_row.add_child(portrait)
	box.add_child(portrait_row)

	var sep := HSeparator.new()
	box.add_child(sep)

	box.add_child(_build_ability_row(DICE_TEX, "Q", "lance un dé (dégâts à distance)"))
	box.add_child(_build_ability_row(FAREWAY_TEX, "W", "fareway — météore qui explose"))
	box.add_child(_build_ability_row(TURBO_TEX, "E", "pilote un robot : vitesse + bouclier"))
	box.add_child(_build_text_only_row("→→", "dash"))
	box.add_child(_build_text_only_row("↑↑", "double saut"))

	_add_hover_bounce(panel)
	return panel


func _build_ability_row(icon_path: String, key: String, description: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	row.add_child(_make_icon(icon_path, Vector2(38, 38)))

	var text_box := VBoxContainer.new()
	text_box.add_theme_constant_override("separation", 0)
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_box)

	var key_label := Label.new()
	key_label.text = key
	_punch_label(key_label, 16, CYAN)
	text_box.add_child(key_label)

	var desc_label := Label.new()
	desc_label.text = description
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_label.custom_minimum_size = Vector2(210, 0)
	desc_label.add_theme_font_size_override("font_size", 13)
	desc_label.add_theme_color_override("font_color", Color(0.92, 0.92, 0.95))
	text_box.add_child(desc_label)

	return row


func _build_text_only_row(key: String, description: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var key_label := Label.new()
	key_label.text = key
	key_label.custom_minimum_size = Vector2(38, 0)
	key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_punch_label(key_label, 16, CYAN)
	row.add_child(key_label)

	var desc_label := Label.new()
	desc_label.text = description
	desc_label.add_theme_font_size_override("font_size", 13)
	desc_label.add_theme_color_override("font_color", Color(0.92, 0.92, 0.95))
	row.add_child(desc_label)

	return row


func _build_coming_soon_card(character_name: String, joke: String) -> PanelContainer:
	var card_size := Vector2(200, 430)
	var panel := _make_card_panel(card_size, Color(0.35, 0.35, 0.4))

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(box)

	var lock_label := Label.new()
	lock_label.text = "🔒"
	lock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lock_label.add_theme_font_size_override("font_size", 48)
	box.add_child(lock_label)

	var name_label := Label.new()
	name_label.text = character_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_punch_label(name_label, 22, Color(0.8, 0.8, 0.85))
	box.add_child(name_label)

	var soon_label := Label.new()
	soon_label.text = "Coming soon"
	soon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_punch_label(soon_label, 16, Color(0.9, 0.4, 0.4))
	box.add_child(soon_label)

	var joke_label := Label.new()
	joke_label.text = joke
	joke_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	joke_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	joke_label.custom_minimum_size = Vector2(160, 0)
	joke_label.add_theme_font_size_override("font_size", 12)
	joke_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	box.add_child(joke_label)

	_add_hover_bounce(panel)
	return panel


func _make_card_panel(card_size: Vector2, accent: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = card_size

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.17, 0.97)
	style.border_color = accent
	style.set_border_width_all(3)
	style.set_corner_radius_all(14)
	style.content_margin_left = 16.0
	style.content_margin_top = 16.0
	style.content_margin_right = 16.0
	style.content_margin_bottom = 16.0
	panel.add_theme_stylebox_override("panel", style)

	return panel


# ---------------------------------------------------------------------------
# Navigation
# ---------------------------------------------------------------------------

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/phase01.tscn")


func _on_characters_pressed() -> void:
	_menu_box.visible = false
	_characters_box.visible = true


func _on_back_pressed() -> void:
	_characters_box.visible = false
	_menu_box.visible = true
