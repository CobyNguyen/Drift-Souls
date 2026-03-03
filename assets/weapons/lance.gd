extends Node3D

@export var min_force := 500.0
@export var max_force := 6000.0
@export var max_charge_time := 1.5
@export var active_time := 0.2
@export var charge_extension := 2.0 

var charging := false
var charge_time := 0.0
var original_position := Vector3.ZERO

var vehicle: VehicleBody3D
var thrusting := false
var timer := 0.0

@onready var hitbox = $Area3D

func _ready():
	hitbox.monitoring = false
	original_position = transform.origin

func _physics_process(delta):
	if charging:
		charge_time += delta
		charge_time = min(charge_time, max_charge_time)
		var charge_ratio = charge_time / max_charge_time
		var forward = transform.basis.z.normalized()
		transform.origin = original_position + forward * charge_extension * charge_ratio

		
	if thrusting:
		timer -= delta
		if timer <= 0:
			stop_thrust()
		

func start_charge():
	if thrusting:
		return
		
	charging = true
	charge_time = 0.0
	
func stop_thrust():
	thrusting = false
	hitbox.monitoring = false

func release_charge():
	if vehicle == null:
		push_error("Vehicle not assigned to Lance!")
		return
		
	if not charging:
		return
	
	transform.origin = original_position
	
	charging = false
	
	# Calculate charge percent
	var charge_ratio = charge_time / max_charge_time
	
	# Interpolate force
	var final_force = lerp(min_force, max_force, charge_ratio)
	print("Charge!", charge_ratio)
	thrusting = true
	timer = active_time
	hitbox.monitoring = true
	
	var forward = -global_transform.basis.z.normalized()
	vehicle.apply_central_impulse(forward * final_force)
	
	
	charge_time = 0.0
