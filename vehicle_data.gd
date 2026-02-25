extends Resource
class_name VehicleData

# Physics / movement
@export var max_steer: float = 1.0
@export var engine_power: float = 300
@export var normal_grip: float = 2.0
@export var drift_grip: float = 1.6
@export var turn_strength: float = 500.0
@export var drift_turn_strength: float = 800.0
@export var top_speed: float = 40.0
@export var boost_multiplier: float = 35.0

# Camera / aiming
@export var mouse_sens: float = 0.003
@export var pitch_min: float = deg_to_rad(-45)
@export var pitch_max: float = deg_to_rad(30)
