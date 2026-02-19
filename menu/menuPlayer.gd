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

# Wheels (change names if yours differ)
@onready var wheel_rl = $BackLeft
@onready var wheel_rr = $BackRight


func _ready() -> void:
	pass	


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
