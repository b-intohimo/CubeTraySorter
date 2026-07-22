extends Node

const MIN_DIFFICULTY := 1
const MAX_DIFFICULTY := 10
const BASE_SHUFFLE_COUNT := 10
const SHUFFLE_INCREMENT_PER_LEVEL := 5

var difficulty: int = 5


func get_shuffle_count() -> int:
	return BASE_SHUFFLE_COUNT + (difficulty - MIN_DIFFICULTY) * SHUFFLE_INCREMENT_PER_LEVEL


func get_difficulty_label() -> String:
	match difficulty:
		1, 2:
			return "Easy"
		3, 4:
			return "Relaxed"
		5, 6:
			return "Normal"
		7, 8:
			return "Challenging"
		_:
			return "Expert"
