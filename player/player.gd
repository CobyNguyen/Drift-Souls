extends VehicleBody3D

const MAX_STEER = 0.8
const ENGINE_POWER = 300

const DRIFT_GRIP = 1.0
const NORMAL_GRIP = 2.1
const DRIFT_STEER_MULT = 1.1

var look_at
var aiming := false
var using_reverse := false
var drift_charge := 0.0
var drifting := false
var cam_yaw := 0.0
var cam_pitch := -10.0


const MOUSE_SENS := 0.003
const PITCH_MIN := deg_to_rad(-45)
const PITCH_MAX := deg_to_rad(30)

@onready var camera_pivot = $CameraPivot
@onready var camera_3d = $CameraPivot/Camera3D
@onready var reverse_camera = $CameraPivot/ReverseCamera
@onready var crosshair = $CameraPivot/CanvasLayer/Control/crosshair
@onready var crosshair_default_pos = crosshair.position

# Wheels (change names if yours differ)
@onready var wheel_rl = $BackLeft
@onready var wheel_rr = $BackRight


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	look_at = global_position
	print(wheel_rl)
	print(wheel_rr)

func _physics_process(delta: float) -> void:

	var steer_input = Input.get_axis("ui_right","ui_left")
	var accel_input = Input.get_axis("ui_down","ui_up")

	# Detect drift
	drifting = Input.is_action_pressed("drift") and linear_velocity.length() > 5.0
	
	# Detect RMB for aiming
	aiming = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	crosshair.visible = aiming
	
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
		
		#Strafing
		var right = transform.basis.x.normalized()
		var forward = transform.basis.z.normalized()
		apply_central_force(right * steer_input * 1200.0)
		
		var forward_speed = linear_velocity.dot(forward)
		linear_velocity = forward * forward_speed + linear_velocity.project(right)
	
		drift_charge += delta * linear_velocity.length()
	else:
		wheel_rl.wheel_friction_slip = NORMAL_GRIP
		wheel_rr.wheel_friction_slip = NORMAL_GRIP
		
		if drift_charge > 2.0:
			apply_central_impulse(transform.basis.z * -drift_charge * 5.0)
		drift_charge	= 0.0

	# CAMERA

	camera_pivot.global_position = camera_pivot.global_position.lerp(global_position, delta * 20.0)

	if aiming:
		# Base rotation from car (yaw only)
		var car_yaw = transform.basis.get_euler().y
		var base_basis = Basis(Vector3.UP, car_yaw)

		# Apply freelook offsets
		var offset_basis = Basis()
		offset_basis = offset_basis.rotated(Vector3.UP, -cam_yaw)
		offset_basis = offset_basis.rotated(Vector3.RIGHT, -cam_pitch)
		camera_pivot.basis = base_basis * offset_basis

		# Crosshair moves relative to its original node position
		var max_offset = 150.0
		var x_offset = clamp(cam_yaw / deg_to_rad(120) * max_offset, -max_offset, max_offset)
		var y_offset = clamp(cam_pitch / deg_to_rad(45) * max_offset, -max_offset, max_offset)
		
		var target_pos = crosshair_default_pos + Vector2(x_offset, -y_offset)
		crosshair.position = crosshair.position.lerp(target_pos, 0.2)
	else:
		# Return crosshair to node's original position
		crosshair.position = crosshair.position.lerp(crosshair_default_pos, 0.2)

		# Return freelook angles
		cam_yaw = lerp(cam_yaw, 0.0, delta * 8.0)
		cam_pitch = lerp(cam_pitch, 0.0, delta * 8.0)

		# Normal camera follow
		camera_pivot.transform = camera_pivot.transform.interpolate_with(transform, delta * 5)


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

func _input(event):
	if event is InputEventMouseMotion and aiming:
		cam_yaw += event.relative.x * MOUSE_SENS
		cam_pitch -= event.relative.y * MOUSE_SENS
		cam_yaw = clamp(cam_yaw, deg_to_rad(-120), deg_to_rad(120))
		cam_pitch = clamp(cam_pitch, PITCH_MIN, PITCH_MAX)
		
