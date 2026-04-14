extends Node

func get_insets(viewport_size: Vector2i) -> Dictionary:
	var safe_rect: Rect2i = DisplayServer.get_display_safe_area()
	return get_insets_from_safe_rect(viewport_size, safe_rect)


func get_insets_from_safe_rect(viewport_size: Vector2i, safe_rect: Rect2i) -> Dictionary:
	if safe_rect.size == Vector2i.ZERO:
		return {
			"left": 0,
			"top": 0,
			"right": 0,
			"bottom": 0,
		}

	var left: int = max(0, safe_rect.position.x)
	var top: int = max(0, safe_rect.position.y)
	var right: int = max(0, viewport_size.x - (safe_rect.position.x + safe_rect.size.x))
	var bottom: int = max(0, viewport_size.y - (safe_rect.position.y + safe_rect.size.y))

	return {
		"left": left,
		"top": top,
		"right": right,
		"bottom": bottom,
	}


func get_safe_rect(viewport_size: Vector2i) -> Rect2i:
	var insets: Dictionary = get_insets(viewport_size)
	return Rect2i(
		insets["left"],
		insets["top"],
		max(0, viewport_size.x - insets["left"] - insets["right"]),
		max(0, viewport_size.y - insets["top"] - insets["bottom"]),
	)
