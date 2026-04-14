extends Control

const CONWAY_REFERENCE_URL := "https://en.wikipedia.org/wiki/Conway%27s_Game_of_Life"

@onready var root_margin: MarginContainer = $Background/MarginContainer
@onready var era_label: Label = $Background/MarginContainer/ContentColumn/HeroPanel/HeroMargin/HeroColumn/EraLabel
@onready var title_label: Label = $Background/MarginContainer/ContentColumn/HeroPanel/HeroMargin/HeroColumn/TitleLabel
@onready var subtitle_label: Label = $Background/MarginContainer/ContentColumn/HeroPanel/HeroMargin/HeroColumn/SubtitleLabel
@onready var description_label: Label = $Background/MarginContainer/ContentColumn/InfoPanel/InfoMargin/InfoColumn/DescriptionLabel
@onready var rules_title_label: Label = $Background/MarginContainer/ContentColumn/InfoPanel/InfoMargin/InfoColumn/RulesTitleLabel
@onready var rules_body_label: Label = $Background/MarginContainer/ContentColumn/InfoPanel/InfoMargin/InfoColumn/RulesBodyLabel
@onready var controls_label: Label = $Background/MarginContainer/ContentColumn/InfoPanel/InfoMargin/InfoColumn/ControlsLabel
@onready var reference_button: Button = $Background/MarginContainer/ContentColumn/InfoPanel/InfoMargin/InfoColumn/ReferenceButton
@onready var start_button: Button = $Background/MarginContainer/ContentColumn/ButtonsColumn/StartButton
@onready var settings_button: Button = $Background/MarginContainer/ContentColumn/ButtonsColumn/SettingsButton
@onready var exit_button: Button = $Background/MarginContainer/ContentColumn/ButtonsColumn/ExitButton


func _ready() -> void:
	start_button.pressed.connect(_on_start_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	exit_button.pressed.connect(_on_exit_button_pressed)
	reference_button.pressed.connect(_on_reference_button_pressed)
	get_viewport().size_changed.connect(_apply_safe_area)
	_apply_safe_area()
	_refresh_texts()


func _refresh_texts() -> void:
	era_label.text = GameSettings.get_text("welcome_era")
	title_label.text = GameSettings.get_text("welcome_title")
	subtitle_label.text = GameSettings.get_text("welcome_subtitle")
	description_label.text = GameSettings.get_text("welcome_description")
	rules_title_label.text = GameSettings.get_text("welcome_rules_title")
	rules_body_label.text = GameSettings.get_text("welcome_rules_body")
	controls_label.text = GameSettings.get_text("welcome_controls")
	reference_button.text = GameSettings.get_text("welcome_reference")
	start_button.text = GameSettings.get_text("start")
	settings_button.text = GameSettings.get_text("settings")
	exit_button.text = GameSettings.get_text("exit")


func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://main.tscn")


func _on_settings_button_pressed() -> void:
	get_tree().change_scene_to_file("res://settings.tscn")


func _on_reference_button_pressed() -> void:
	OS.shell_open(CONWAY_REFERENCE_URL)


func _apply_safe_area() -> void:
	var viewport_size := Vector2i(get_viewport_rect().size)
	var insets: Dictionary = SafeArea.get_insets(viewport_size)
	root_margin.add_theme_constant_override("margin_left", max(8, int(ceil(insets["left"] * 0.5)) + 2))
	root_margin.add_theme_constant_override("margin_top", max(10, int(ceil(insets["top"] * 0.5)) + 2))
	root_margin.add_theme_constant_override("margin_right", max(8, int(ceil(insets["right"] * 0.5)) + 2))
	root_margin.add_theme_constant_override("margin_bottom", max(10, int(ceil(insets["bottom"] * 0.5)) + 2))


func _on_exit_button_pressed() -> void:
	get_tree().quit()
