extends Control

func _on_new_game_button_pressed():
    get_tree().change_scene_to_file("res://scenes/DayView.tscn")

func _on_exit_button_pressed():
    get_tree().quit()
