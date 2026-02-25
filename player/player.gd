# Player.gd
extends Node3D

@export var vehicle_node_path: NodePath

# Vehicle & camera references (initialized in _ready)
var vehicle: VehicleBody3D
var camera_pivot
var camera_3d
var reverse_camera
var crosshair
var crosshair_default_pos
var speed_bar
var boost_bar
var look_at

# Wheel references
var wheel_fl
var wheel_fr
var wheel_rl
var wheel_rr

# Driving state
var drifting := false
var drift_charge := 0.0
var aiming := false
var cam_yaw := 0.0
var cam_pitch := -10.0
var using_reverse := false

# vehicle_data
var BOOST_MULT = 35.0
var TOP_SPEED = 40
var MAX_STEER = 1.0
var ENGINE_POWER = 300
var DRIFT_GRIP = 1.6
var NORMAL_GRIP = 2.0
var PITCH_MAX
var PITCH_MIN
var TURN_STRENGTH = 500.0
var DRIFT_TURN_STRENGTH = 800
var MOUSE_SENS = .003



func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	look_at = global_position
	# --- Get vehicle dynamically ---
	vehicle = get_node(vehicle_node_path)
	if vehicle == null:
		push_error("Vehicle node not found at path: %s" % vehicle_node_path)
		return

	# --- Wheels ---
	wheel_fl = vehicle.get_node("FrontLeft") as VehicleWheel3D
	wheel_fr = vehicle.get_node("FrontRight") as VehicleWheel3D
	wheel_rl = vehicle.get_node("BackLeft") as VehicleWheel3D
	wheel_rr = vehicle.get_node("BackRight") as VehicleWheel3D
	# Fetch vehicle data
	if vehicle.vehicle_data != null:
		var data = vehicle.vehicle_data
		MAX_STEER = data.max_steer
		ENGINE_POWER = data.engine_power
		DRIFT_GRIP = data.drift_grip
		NORMAL_GRIP = data.normal_grip
		TURN_STRENGTH = data.turn_strength
		DRIFT_TURN_STRENGTH = data.drift_turn_strength
		TOP_SPEED = data.top_speed
		BOOST_MULT = data.boost_multiplier
		MOUSE_SENS = data.mouse_sens
		PITCH_MAX = data.pitch_max
		PITCH_MIN = data.pitch_min


	# --- Camera & UI ---
	camera_pivot = vehicle.get_node("CameraPivot")
	camera_3d = camera_pivot.get_node("Camera3D")
	reverse_camera = camera_pivot.get_node("ReverseCamera")
	crosshair = camera_pivot.get_node("CanvasLayer/Control/crosshair")
	crosshair_default_pos = crosshair.position
	speed_bar = camera_pivot.get_node("CanvasLayer/Control/SpeedBar")
	boost_bar = camera_pivot.get_node("CanvasLayer/Control/BoostBar")
	crosshair.visible = false
	
func is_grounded() -> bool:
	return wheel_fl.is_in_contact() or wheel_fr.is_in_contact() or wheel_rl.is_in_contact() or wheel_rr.is_in_contact()

func _physics_process(delta: float) -> void:
	if vehicle == null:
		return

	var steer_input = Input.get_axis("ui_right","ui_left")
	var accel_input = Input.get_axis("ui_down","ui_up")
	var speed = vehicle.linear_velocity.length()

	# --- Update UI ---
	speed_bar.value = speed
	boost_bar.value = drift_charge
	var fill_style = boost_bar.get_theme_stylebox("fill")
	if drift_charge > 20:
		fill_style.bg_color = Color.RED
	elif drift_charge > 10:
		fill_style.bg_color = Color.ORANGE
	else:
		fill_style.bg_color = Color.YELLOW

	# --- Detect drift ---
	drifting = Input.is_action_pressed("drift") and speed > 5.0 and is_grounded()

	# --- Detect aiming ---
	aiming = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	crosshair.visible = aiming

	# --- Steering ---
	var speed_factor = clamp(speed / 20.0, 0.3, 1.0)
	var steer_amount = steer_input * MAX_STEER * speed_factor
	var steer_speed = 4.0 if drifting else 2.5
	vehicle.steering = move_toward(vehicle.steering, steer_amount, delta * steer_speed)

	# --- Engine ---
	var speed_ratio = clamp(speed / 40.0, 0.0, 1.0)
	var accel_multiplier = lerp(2.2, 1.0, speed_ratio)
	vehicle.engine_force = accel_input * ENGINE_POWER * accel_multiplier

	# --- Drift grip & forces ---
	#var forward = -vehicle.transform.basis.z.normalized()
	var right = vehicle.transform.basis.x.normalized()

	if is_grounded():
		vehicle.apply_central_force(right * steer_input * TURN_STRENGTH)
	
	# FIX THIS
	if drifting:
		for wheel in [wheel_fl, wheel_fr, wheel_rl, wheel_rr]:
			wheel.wheel_friction_slip = DRIFT_GRIP
		vehicle.apply_central_force(right * steer_input * DRIFT_TURN_STRENGTH)

		vehicle.engine_force = accel_input * ENGINE_POWER * accel_multiplier
		vehicle.engine_force *= 1.3
		var sideways_speed = vehicle.linear_velocity.dot(right)
		drift_charge += delta * abs(sideways_speed)
		drift_charge = min(drift_charge, 30)
	else:
		for wheel in [wheel_fl, wheel_fr, wheel_rl, wheel_rr]:
			wheel.wheel_friction_slip = NORMAL_GRIP

	# --- Drift boost ---
	if Input.is_action_just_released("drift") and drift_charge > 1.0:
		var boost_dir = vehicle.linear_velocity.normalized()
		boost_dir += right * steer_input * 0.5
		boost_dir = boost_dir.normalized()
		if boost_dir.length() < 1.0:
			boost_dir = -vehicle.transform.basis.z
		boost_dir.y = 0
		boost_dir = boost_dir.normalized()
		print("BOOST!", drift_charge)
		drift_charge = 0.0

	# --- Camera ---
	camera_pivot.global_position = camera_pivot.global_position.lerp(vehicle.global_position, delta * 20.0)

	if aiming:
		var car_yaw = vehicle.transform.basis.get_euler().y
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
		var car_yaw = vehicle.transform.basis.get_euler().y
		var base_basis = Basis(Vector3.UP, car_yaw)
		
		# Apply freelook offsets
		var offset_basis = Basis()
		offset_basis = offset_basis.rotated(Vector3.UP, -cam_yaw)
		offset_basis = offset_basis.rotated(Vector3.RIGHT, -cam_pitch)
		camera_pivot.basis = base_basis * offset_basis

		_check_camera_switch()

func _check_camera_switch():
	var speed = vehicle.linear_velocity.length()
	var reverse_input = Input.get_axis("ui_down","ui_up") < 0
	var local_vel = vehicle.transform.basis.inverse() * vehicle.linear_velocity
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
