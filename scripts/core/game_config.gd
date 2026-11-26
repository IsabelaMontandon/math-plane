extends RefCounted

static var _selected_season: String = "summer"
static var _selected_difficulty: String = "explorer"

const SEASONS: Dictionary = {
	"summer": {
		"operation": "sum",
		"symbol": "+",
		"initial_value": 0,
		"targets": [6, 9, 12, 15, 11, 18, 14, 20, 17, 24],
		"gameplay_background": "res://assets/images/gameplay/summer/background.png",
		"difficulty_background": "res://assets/images/difficulty/backgrounds/summer.png",
		"difficulty_title": "res://assets/images/difficulty/title/summer.png"
	},
	"autumn": {
		"operation": "multiply",
		"symbol": "×",
		"initial_value": 1,
		"targets": [6, 8, 10, 12, 15, 18, 20, 24, 30, 36],
		"gameplay_background": "res://assets/images/gameplay/autumn/background.png",
		"difficulty_background": "res://assets/images/difficulty/backgrounds/autumn.png",
		"difficulty_title": "res://assets/images/difficulty/title/autumn.png"
	},
	"winter": {
		"operation": "subtract",
		"symbol": "−",
		"starts": [12, 15, 18, 20, 24, 25, 28, 30, 32, 36],
		"targets": [0, 2, 1, 3, 0, 4, 2, 5, 1, 0],
		"gameplay_background": "res://assets/images/gameplay/winter/background.webp",
		"difficulty_background": "res://assets/images/difficulty/backgrounds/winter.png",
		"difficulty_title": "res://assets/images/difficulty/title/winter.png",
		"three_star_seconds": {"explorer": 90.0, "pilot": 120.0, "commander": 90.0}
	},
	"spring": {
		"operation": "divide",
		"symbol": "÷",
		"starts": [12, 18, 24, 30, 36, 40, 48, 54, 60, 72],
		"targets": [1, 3, 2, 5, 3, 2, 4, 3, 5, 2],
		"gameplay_background": "res://assets/images/gameplay/spring/background.png",
		"difficulty_background": "res://assets/images/difficulty/backgrounds/spring.png",
		"difficulty_title": "res://assets/images/difficulty/title/spring.png",
		"three_star_seconds": {"explorer": 90.0, "pilot": 120.0, "commander": 90.0}
	}
}

static func set_season(season: String) -> void:
	if SEASONS.has(season):
		_selected_season = season


static func get_selected_season() -> String:
	return _selected_season


static func set_difficulty(difficulty: String) -> void:
	if difficulty in ["explorer", "pilot", "commander"]:
		_selected_difficulty = difficulty


static func get_selected_difficulty() -> String:
	return _selected_difficulty


static func get_current_season_data() -> Dictionary:
	if SEASONS.has(_selected_season):
		return SEASONS[_selected_season]
	return SEASONS["summer"]
