extends Control
@onready var pauseMenu = preload("res://menu/pause_menu.tscn")


func resume():
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	visible = false
	

func pause():
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	visible = true

func testEsc():
	if Input.is_action_just_pressed("ui_cancel"):
		if get_tree().paused:
			resume()
		else:
			pause()


func _ready() -> void:
	visible = false
	

func _process(delta):
	testEsc()
	if Input.is_action_just_pressed("Restart scene"):
		get_tree().reload_current_scene()

func _on_options_pressed():
	pause()
	#get_tree().change_scene_to_file("res://menu/pause_menu.tscn")



func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_resume_pressed() -> void:
	resume()
