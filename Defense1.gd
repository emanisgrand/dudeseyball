extends RigidBody3D

@onready var upright_reference = $UprightReference
#Spring constant - adjust to make the correction stronger/weaker
@export var k:float = 10.0
@export var tilt_threshold_degrees:float = 10.0

@export_group("Movement variables")
@export var move_force:float = 1.0
@export var deadzone:float = 0.2

var input_vector = Vector3.ZERO

func _physics_process(delta):
	# Start with zero vector for input
	var axis_x = 0.0
	var axis_y = 0.0
	
	# Add joystick input to the axis if ajoystick is connected and active
	if Input.is_joy_known(0):
		axis_x += Input.get_joy_axis(0, 0)
		axis_y += Input.get_joy_axis(0, 1) 
	else:
		# Add keyboard input to the axes
		axis_x += Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
		axis_y += Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")

	# Apply deadzone
	if (abs(axis_x) < deadzone):
		axis_x = 0
	if (abs(axis_y) < deadzone):
		axis_y = 0
	
	input_vector = Vector3(-axis_x, 0, -axis_y).normalized()

func _integrate_forces(state):
	var current_orientation = global_transform.basis
	var current_up = current_orientation.y
	var target_up = Vector3.UP
	var tilt = current_up.angle_to(target_up)
	
	# Determine if the body needs to be corrected based on the tilt angle
	if tilt > deg_to_rad(tilt_threshold_degrees):
		print("tilt > tilt threshold. x and z locked.")
		# Correction is needed, lock the linear X and Z velocities
		axis_lock_linear_x = true
		axis_lock_linear_z = true
	
		# Apply a correction force to reorient to upright
		var correction_axis = current_up.cross(target_up).normalized()
		var correction_torque = correction_axis * (k * tilt)
		apply_torque_impulse(correction_torque)
	else: 
		#No correction needed, allow movement
		axis_lock_linear_x = false
		axis_lock_linear_z = false
		#Transform the input vector from local to global space
		if input_vector.length() > 0:
			apply_central_impulse(input_vector * move_force)
