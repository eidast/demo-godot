extends Control

const CONWAY_REFERENCE_URL := "https://en.wikipedia.org/wiki/Conway%27s_Game_of_Life"

@onready var root_margin: MarginContainer = $Background/MarginContainer
@onready var scroll_container: ScrollContainer = $Background/MarginContainer/ScrollContainer
@onready var content_column: VBoxContainer = $Background/MarginContainer/ScrollContainer/ContentColumn
@onready var hero_panel: PanelContainer = $Background/MarginContainer/ScrollContainer/ContentColumn/HeroPanel
@onready var hero_margin: MarginContainer = $Background/MarginContainer/ScrollContainer/ContentColumn/HeroPanel/HeroMargin
@onready var info_margin: MarginContainer = $Background/MarginContainer/ScrollContainer/ContentColumn/InfoPanel/InfoMargin
@onready var buttons_column: VBoxContainer = $Background/MarginContainer/ScrollContainer/ContentColumn/ButtonsColumn
@onready var era_label: Label = $Background/MarginContainer/ScrollContainer/ContentColumn/HeroPanel/HeroMargin/HeroColumn/EraLabel
@onready var title_label: Label = $Background/MarginContainer/ScrollContainer/ContentColumn/HeroPanel/HeroMargin/HeroColumn/TitleLabel
@onready var subtitle_label: Label = $Background/MarginContainer/ScrollContainer/ContentColumn/HeroPanel/HeroMargin/HeroColumn/SubtitleLabel
@onready var description_label: Label = $Background/MarginContainer/ScrollContainer/ContentColumn/InfoPanel/InfoMargin/InfoColumn/DescriptionLabel
@onready var rules_title_label: Label = $Background/MarginContainer/ScrollContainer/ContentColumn/InfoPanel/InfoMargin/InfoColumn/RulesTitleLabel
@onready var rules_body_label: Label = $Background/MarginContainer/ScrollContainer/ContentColumn/InfoPanel/InfoMargin/InfoColumn/RulesBodyLabel
@onready var controls_label: Label = $Background/MarginContainer/ScrollContainer/ContentColumn/InfoPanel/InfoMargin/InfoColumn/ControlsLabel
@onready var reference_button: Button = $Background/MarginContainer/ScrollContainer/ContentColumn/InfoPanel/InfoMargin/InfoColumn/ReferenceButton
@onready var start_button: Button = $Background/MarginContainer/ScrollContainer/ContentColumn/ButtonsColumn/StartButton
@onready var settings_button: Button = $Background/MarginContainer/ScrollContainer/ContentColumn/ButtonsColumn/SettingsButton
@onready var exit_button: Button = $Background/MarginContainer/ScrollContainer/ContentColumn/ButtonsColumn/ExitButton


func _ready() -> void:
	start_button.pressed.connect(_on_start_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	exit_button.pressed.connect(_on_exit_button_pressed)
	reference_button.pressed.connect(_on_reference_button_pressed)
	get_viewport().size_changed.connect(_apply_safe_area)
	_apply_safe_area()
	_apply_compact_layout()
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
	_apply_compact_layout()


func _apply_compact_layout() -> void:
	var viewport_height: float = get_viewport_rect().size.y
	var compact: bool = viewport_height < 860.0
	var tight: bool = viewport_height < 760.0

	content_column.add_theme_constant_override("separation", 12 if compact else 18)
	buttons_column.add_theme_constant_override("separation", 10 if compact else 14)
	hero_margin.add_theme_constant_override("margin_left", 16 if compact else 20)
	hero_margin.add_theme_constant_override("margin_top", 16 if compact else 20)
	hero_margin.add_theme_constant_override("margin_right", 16 if compact else 20)
	hero_margin.add_theme_constant_override("margin_bottom", 16 if compact else 20)
	info_margin.add_theme_constant_override("margin_left", 16 if compact else 20)
	info_margin.add_theme_constant_override("margin_top", 16 if compact else 20)
	info_margin.add_theme_constant_override("margin_right", 16 if compact else 20)
	info_margin.add_theme_constant_override("margin_bottom", 16 if compact else 20)
	hero_panel.custom_minimum_size = Vector2(0, 236 if tight else (256 if compact else 292))
	reference_button.custom_minimum_size = Vector2(0, 62 if tight else (68 if compact else 74))
	start_button.custom_minimum_size = Vector2(0, 78 if tight else (84 if compact else 96))
	settings_button.custom_minimum_size = Vector2(0, 78 if tight else (84 if compact else 96))
	exit_button.custom_minimum_size = Vector2(0, 78 if tight else (84 if compact else 96))

	era_label.add_theme_font_size_override("font_size", 26 if tight else (28 if compact else 32))
	title_label.add_theme_font_size_override("font_size", 66 if tight else (74 if compact else 84))
	subtitle_label.add_theme_font_size_override("font_size", 34 if tight else (38 if compact else 42))
	description_label.add_theme_font_size_override("font_size", 26 if tight else (28 if compact else 32))
	rules_title_label.add_theme_font_size_override("font_size", 30 if tight else (32 if compact else 34))
	rules_body_label.add_theme_font_size_override("font_size", 24 if tight else (26 if compact else 30))
	controls_label.add_theme_font_size_override("font_size", 24 if tight else (26 if compact else 30))
	reference_button.add_theme_font_size_override("font_size", 24 if tight else (26 if compact else 30))
	start_button.add_theme_font_size_override("font_size", 28 if tight else (30 if compact else 34))
	settings_button.add_theme_font_size_override("font_size", 28 if tight else (30 if compact else 34))
	exit_button.add_theme_font_size_override("font_size", 28 if tight else (30 if compact else 34))


func _on_exit_button_pressed() -> void:
	get_tree().quit()
