extends Node

const LANGUAGE_SPANISH := "es"
const LANGUAGE_ENGLISH := "en"

const TEXTS := {
	LANGUAGE_SPANISH: {
		"welcome_title": "Game of Life",
		"welcome_subtitle": "Tributo pixelart al automata celular",
		"welcome_era": "JOHN HORTON CONWAY  1970",
		"welcome_description": "Un juego de cero jugadores donde un patron inicial basta para generar generaciones, osciladores y naves sobre una grilla infinita.",
		"welcome_tribute": "Basado en Conway's Game of Life, ideado por John Horton Conway en 1970. Esta portada enlaza la referencia historica de Wikipedia.",
		"welcome_rules_title": "Reglas simplificadas",
		"welcome_rules_body": "1. Una celula viva con menos de 2 vecinas muere.\n2. Una viva con 2 o 3 vecinas sobrevive.\n3. Una viva con mas de 3 vecinas muere.\n4. Una celula muerta con exactamente 3 vecinas nace.",
		"welcome_controls": "Movil: toca celdas para activarlas. Usa el panel para reproducir, pausar, limpiar o aleatorizar la simulacion.",
		"welcome_reference": "Abrir Wikipedia",
		"start": "Comenzar",
		"settings": "Configuracion",
		"exit": "Salir",
		"settings_title": "Configuracion",
		"settings_language": "Idioma",
		"settings_language_note": "El cambio se aplica de inmediato en menus y en la interfaz del juego.",
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
		"welcome_subtitle": "A pixel-art tribute to the cellular automaton",
		"welcome_era": "JOHN HORTON CONWAY  1970",
		"welcome_description": "A zero-player game where a single seed pattern can produce generations, oscillators, and spaceships across an infinite grid.",
		"welcome_tribute": "Based on Conway's Game of Life, devised by John Horton Conway in 1970. This cover links to the historical Wikipedia reference.",
		"welcome_rules_title": "Simplified rules",
		"welcome_rules_body": "1. A live cell with fewer than 2 neighbours dies.\n2. A live cell with 2 or 3 neighbours survives.\n3. A live cell with more than 3 neighbours dies.\n4. A dead cell with exactly 3 neighbours becomes alive.",
		"welcome_controls": "Mobile: tap cells to activate them. Use the panel to play, pause, clear, or randomize the simulation.",
		"welcome_reference": "Open Wikipedia",
		"start": "Start",
		"settings": "Settings",
		"exit": "Exit",
		"settings_title": "Settings",
		"settings_language": "Language",
		"settings_language_note": "The change applies immediately to menus and to the in-game interface.",
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

var current_language := LANGUAGE_ENGLISH


func set_language(language_code: String) -> void:
	if not TEXTS.has(language_code):
		return
	current_language = language_code


func get_language() -> String:
	return current_language


func get_text(key: String) -> String:
	var language_texts: Dictionary = TEXTS.get(current_language, TEXTS[LANGUAGE_ENGLISH])
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
