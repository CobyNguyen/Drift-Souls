extends VehicleBody3D

const MAX_STEER = 0.8
const ENGINE_POWER = 300

var look_at

var drift_charge

var spawn_transform  # store initial position/rotation

func _ready() -> void:
	#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)]
	look_at = global_position
	spawn_transform = global_transform  # store initial position and rotation


func _physics_process(delta: float) -> void:
	steering = move_toward(steering, Input.get_axis("ui_right","ui_left") * MAX_STEER, delta * 2.5)
	engine_force = Input.get_axis("ui_down","ui_up") * ENGINE_POWER

	# Reset car to spawn position when spacebar is pressed
	if Input.is_action_just_pressed("reset_car"):  
		global_transform = spawn_transform
		linear_velocity = Vector3.ZERO   # stop any movement
		angular_velocity = Vector3.ZERO  # stop rotation
