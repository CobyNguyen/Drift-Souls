# Corolla.gd
extends VehicleBody3D

@export var vehicle_data: VehicleData  # Resource with engine, grip, etc.

@onready var wheel_fl = $FrontLeft   # Adjust according to your wheel nodes
@onready var wheel_fr = $FrontRight
@onready var wheel_rl = $BackLeft
@onready var wheel_rr = $BackRight
