extends VehicleBody3D

const MAX_STEER = 0.8
const ENGINE_POWER = 300

const DRIFT_GRIP = 1.0
const NORMAL_GRIP = 3.5
const DRIFT_STEER_MULT = 1.1

var look_at
var using_reverse := false
var drift_charge := 0.0
var drifting := false

@onready var camera_pivot = $CameraPivot
@onready var camera_3d = $CameraPivot/Camera3D
@onready var reverse_camera = $CameraPivot/ReverseCamera

# Wheels (change names if yours differ)
@onready var wheel_rl = $BackLeft
@onready var wheel_rr = $BackRight


func _ready() -> void:
	look_at = global_position
	print(wheel_rl)
	print(wheel_rr)



func _physics_process(delta: float) -> void:

	var steer_input = Input.get_axis("ui_right","ui_left")
	var accel_input = Input.get_axis("ui_down","ui_up")

	# Detect drift
	drifting = Input.is_action_pressed("drift") and linear_velocity.length() > 5.0

	# Steering
	var steer_amount = steer_input * MAX_STEER
	if drifting:
		steer_amount *= DRIFT_STEER_MULT
	
	steering = move_toward(steering, steer_amount, delta * 2.5)

	# Engine
	engine_force = accel_input * ENGINE_POWER

	# Drift grip
	if drifting:
		wheel_rl.wheel_friction_slip = DRIFT_GRIP
		wheel_rr.wheel_friction_slip = DRIFT_GRIP
		
		# Sideways slide force (arcade feel)
		var right_dir = transform.basis.x
		apply_central_force(right_dir * steer_input * 1200.0)
		
		# Charge drift meter
		drift_charge += delta * linear_velocity.length()
	else:
		wheel_rl.wheel_friction_slip = NORMAL_GRIP
		wheel_rr.wheel_friction_slip = NORMAL_GRIP
		
		drift_charge = max(drift_charge - delta * 2.0, 0.0)

	# Camera follow
	camera_pivot.global_position = camera_pivot.global_position.lerp(global_position, delta * 20.0)
	camera_pivot.transform = camera_pivot.transform.interpolate_with(transform, delta * 5)

	look_at = look_at.lerp(global_position + linear_velocity, delta * 9.0)
	camera_3d.look_at(look_at)

	_check_camera_switch()


func _check_camera_switch():
	var speed = linear_velocity.length()
	var reverse_input = Input.get_axis("ui_down", "ui_up") < 0

	var local_vel = transform.basis.inverse() * linear_velocity
	var moving_backward = local_vel.z < -0.1

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
