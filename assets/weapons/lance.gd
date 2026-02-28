extends Node3D

@export var damage := 20
@export var thrust_force := 30.0
@export var active_time := 0.2

var thrusting := false
var timer := 0.0

@onready var hitbox = $Area3D

func _ready():
	hitbox.monitoring = false

func _physics_process(delta):
	if thrusting:
		timer -= delta 
		visible = true
		if timer <= 0:
			stop_thrust()
		

func thrust():
	if thrusting:
		return
	
	thrusting = true
	timer = active_time
	hitbox.monitoring = true
	
	var forward = -global_transform.basis.z.normalized()
	
	var vehicle = get_parent().get_parent()  # mount → vehicle
	if vehicle is VehicleBody3D:
		vehicle.apply_central_impulse(forward * thrust_force)
	thrusting = true
	timer = active_time
	hitbox.monitoring = true
	
func stop_thrust():
	thrusting = false
	hitbox.monitoring = false
