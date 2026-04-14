extends Control

@onready var root_margin: MarginContainer = $Background/MarginContainer
@onready var title_label: Label = $Background/MarginContainer/CenterContainer/Panel/PanelMargin/VBoxContainer/TitleLabel
@onready var language_label: Label = $Background/MarginContainer/CenterContainer/Panel/PanelMargin/VBoxContainer/LanguageLabel
@onready var language_selector: OptionButton = $Background/MarginContainer/CenterContainer/Panel/PanelMargin/VBoxContainer/LanguageSelector
@onready var language_note_label: Label = $Background/MarginContainer/CenterContainer/Panel/PanelMargin/VBoxContainer/LanguageNoteLabel
@onready var back_button: Button = $Background/MarginContainer/CenterContainer/Panel/PanelMargin/VBoxContainer/BackButton

var language_codes: Array[String] = []


func _ready() -> void:
	back_button.pressed.connect(_on_back_button_pressed)
	language_selector.item_selected.connect(_on_language_selected)
	get_viewport().size_changed.connect(_apply_safe_area)
	_apply_safe_area()
	_refresh_ui()


func _refresh_ui() -> void:
	title_label.text = GameSettings.get_text("settings_title")
	language_label.text = GameSettings.get_text("settings_language")
	language_note_label.text = GameSettings.get_text("settings_language_note")
	back_button.text = GameSettings.get_text("settings_back")

	language_selector.clear()
	language_codes.clear()

	var options := GameSettings.get_language_options()
	for option in options:
		language_selector.add_item(option["label"])
		language_codes.append(option["code"])

	var selected_index := language_codes.find(GameSettings.get_language())
	if selected_index >= 0:
		language_selector.select(selected_index)


func _on_language_selected(index: int) -> void:
	if index < 0 or index >= language_codes.size():
		return

	GameSettings.set_language(language_codes[index])
	_refresh_ui()


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://welcome.tscn")


func _apply_safe_area() -> void:
	var viewport_size := Vector2i(get_viewport_rect().size)
	var insets: Dictionary = SafeArea.get_insets(viewport_size)
	root_margin.add_theme_constant_override("margin_left", max(8, int(ceil(insets["left"] * 0.5)) + 2))
	root_margin.add_theme_constant_override("margin_top", max(10, int(ceil(insets["top"] * 0.5)) + 2))
	root_margin.add_theme_constant_override("margin_right", max(8, int(ceil(insets["right"] * 0.5)) + 2))
	root_margin.add_theme_constant_override("margin_bottom", max(10, int(ceil(insets["bottom"] * 0.5)) + 2))
