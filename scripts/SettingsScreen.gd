extends Control

@onready var title_label: Label = $Background/MarginContainer/VBoxContainer/TitleLabel
@onready var language_label: Label = $Background/MarginContainer/VBoxContainer/LanguageLabel
@onready var language_selector: OptionButton = $Background/MarginContainer/VBoxContainer/LanguageSelector
@onready var back_button: Button = $Background/MarginContainer/VBoxContainer/BackButton

var language_codes: Array[String] = []


func _ready() -> void:
	back_button.pressed.connect(_on_back_button_pressed)
	language_selector.item_selected.connect(_on_language_selected)
	_refresh_ui()


func _refresh_ui() -> void:
	title_label.text = GameSettings.get_text("settings_title")
	language_label.text = GameSettings.get_text("settings_language")
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
