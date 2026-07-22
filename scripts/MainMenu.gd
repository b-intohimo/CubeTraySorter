extends Control

@onready var difficulty_slider: HSlider = $CenterContainer/VBoxContainer/DifficultyRow/DifficultySlider
@onready var difficulty_label: Label = $CenterContainer/VBoxContainer/DifficultyLabel
@onready var difficulty_desc_label: Label = $CenterContainer/VBoxContainer/DifficultyDescLabel


func _ready() -> void:
	difficulty_slider.value = GameConfig.difficulty
	_update_difficulty_labels()


func _on_difficulty_slider_value_changed(value: float) -> void:
	GameConfig.difficulty = int(value)
	_update_difficulty_labels()


func _update_difficulty_labels() -> void:
	difficulty_label.text = "Difficulty: %d" % GameConfig.difficulty
	difficulty_desc_label.text = GameConfig.get_difficulty_label()


func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Game.tscn")
