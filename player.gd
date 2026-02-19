extends VehicleBody3D

const MAX_STEER = 0.8
const ENGINE_POWER = 300

var look_at
var using_reverse := false   # remembers current camera
var drift_charge

@onready var camera_pivot = $CameraPivot
@onready var camera_3d = $CameraPivot/Camera3D
@onready var reverse_camera = $CameraPivot/ReverseCamera




func _ready() -> void:
	#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	look_at = global_position


func _physics_process(delta: float) -> void:
	steering = move_toward(steering, Input.get_axis("ui_right","ui_left") * MAX_STEER, delta * 2.5)
	engine_force = Input.get_axis("ui_down","ui_up") * ENGINE_POWER
	
	camera_pivot.global_position = camera_pivot.global_position.lerp(global_position, delta * 20.0)
	camera_pivot.transform = camera_pivot.transform.interpolate_with(transform, delta * 5)
	
	look_at = look_at.lerp(global_position + linear_velocity, delta * 5.0)
	camera_3d.look_at(look_at)
	
	_check_camera_switch()


func _check_camera_switch():
	var speed = linear_velocity.length()
	var reverse_input = Input.get_axis("ui_down", "ui_up") < 0
	
	# Local velocity tells forward/back direction relative to car
	var local_vel = transform.basis.inverse() * linear_velocity
	
	var moving_backward = local_vel.z < -0.1
	
	# Conditions to enable reverse camera
	if reverse_input and (speed < 3.0 or moving_backward):
		if not using_reverse:
			camera_3d.current = false
			reverse_camera.current = true
			using_reverse = true
	else:
		if using_reverse:
			camera_3d.current = true
			reverse_camera.current = false
			using_reverse = false
