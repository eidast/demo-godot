extends Control

@onready var title_label: Label = $Background/MarginContainer/VBoxContainer/TitleLabel
@onready var subtitle_label: Label = $Background/MarginContainer/VBoxContainer/SubtitleLabel
@onready var description_label: Label = $Background/MarginContainer/VBoxContainer/DescriptionLabel
@onready var controls_label: Label = $Background/MarginContainer/VBoxContainer/ControlsLabel
@onready var start_button: Button = $Background/MarginContainer/VBoxContainer/ButtonsRow/StartButton
@onready var settings_button: Button = $Background/MarginContainer/VBoxContainer/ButtonsRow/SettingsButton
@onready var exit_button: Button = $Background/MarginContainer/VBoxContainer/ButtonsRow/ExitButton


func _ready() -> void:
	start_button.pressed.connect(_on_start_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	exit_button.pressed.connect(_on_exit_button_pressed)
	_refresh_texts()


func _refresh_texts() -> void:
	title_label.text = GameSettings.get_text("welcome_title")
	subtitle_label.text = GameSettings.get_text("welcome_subtitle")
	description_label.text = GameSettings.get_text("welcome_description")
	controls_label.text = GameSettings.get_text("welcome_controls")
	start_button.text = GameSettings.get_text("start")
	settings_button.text = GameSettings.get_text("settings")
	exit_button.text = GameSettings.get_text("exit")


func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://main.tscn")


func _on_settings_button_pressed() -> void:
	get_tree().change_scene_to_file("res://settings.tscn")


func _on_exit_button_pressed() -> void:
	get_tree().quit()
