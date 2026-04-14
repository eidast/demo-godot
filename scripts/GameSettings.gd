extends Node

const LANGUAGE_SPANISH := "es"
const LANGUAGE_ENGLISH := "en"

const TEXTS := {
	LANGUAGE_SPANISH: {
		"welcome_title": "Game of Life",
		"welcome_subtitle": "Tu primer simulador en Godot",
		"welcome_description": "Activa celdas, ejecuta la simulacion y observa como evolucionan los patrones segun las reglas de Conway.",
		"welcome_controls": "Controles: clic izquierdo para cambiar celdas, Espacio para play/pausa, N para avanzar.",
		"start": "Comenzar",
		"settings": "Configuracion",
		"exit": "Salir",
		"settings_title": "Configuracion",
		"settings_language": "Idioma",
		"settings_back": "Volver",
		"language_name_es": "Espanol",
		"language_name_en": "Ingles",
		"step": "Paso",
		"play": "Play",
		"pause": "Pausar",
		"clear": "Limpiar",
		"random": "Aleatorio",
		"seed": "Patron",
		"speed": "Velocidad",
		"generation": "Gen: %d",
		"live_cells": "Vivas: %d",
		"back": "Menu",
	},
	LANGUAGE_ENGLISH: {
		"welcome_title": "Game of Life",
		"welcome_subtitle": "Your first simulator in Godot",
		"welcome_description": "Activate cells, run the simulation, and watch patterns evolve under Conway's rules.",
		"welcome_controls": "Controls: left click toggles cells, Space plays or pauses, N advances one step.",
		"start": "Start",
		"settings": "Settings",
		"exit": "Exit",
		"settings_title": "Settings",
		"settings_language": "Language",
		"settings_back": "Back",
		"language_name_es": "Spanish",
		"language_name_en": "English",
		"step": "Step",
		"play": "Play",
		"pause": "Pause",
		"clear": "Clear",
		"random": "Random",
		"seed": "Pattern",
		"speed": "Speed",
		"generation": "Gen: %d",
		"live_cells": "Live: %d",
		"back": "Menu",
	},
}

var current_language := LANGUAGE_SPANISH


func set_language(language_code: String) -> void:
	if not TEXTS.has(language_code):
		return
	current_language = language_code


func get_language() -> String:
	return current_language


func get_text(key: String) -> String:
	var language_texts: Dictionary = TEXTS.get(current_language, TEXTS[LANGUAGE_SPANISH])
	return language_texts.get(key, key)


func get_language_options() -> Array[Dictionary]:
	return [
		{
			"code": LANGUAGE_SPANISH,
			"label": get_text("language_name_es"),
		},
		{
			"code": LANGUAGE_ENGLISH,
			"label": get_text("language_name_en"),
		},
	]
