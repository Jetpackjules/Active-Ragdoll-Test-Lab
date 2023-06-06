extends RigidBody2D

var speed := 400.0

var jump_power := 1000.0


var bad_spines := 0

#var spin_power := 50

var power := 500.0

#again the varaible to store desired angle
var new_desired_angle := 0.0

var locked: bool = true

var spin_dir: int
var holding_something := false
#onready var head = get_node("Head")
var grabbed_item = null

var spin_multiplier := 1.0
#var added_up_velocity = 0
onready var Leg_L_up = get_node("Leg_L_up")
onready var Leg_L_down = get_node("Leg_L_down")
onready var Leg_R_up = get_node("Leg_R_up")
onready var Leg_R_down = get_node("Leg_R_down")


onready var spine1 = get_node("Spine6/Spine5/Spine4/Spine3/Spine2/Spine1")
onready var spine2 = get_node("Spine6/Spine5/Spine4/Spine3/Spine2")
onready var spine3 = get_node("Spine6/Spine5/Spine4/Spine3")
onready var spine4 = get_node("Spine6/Spine5/Spine4")
onready var spine5 = get_node("Spine6/Spine5")
onready var spine6 = get_node("Spine6")

#onready var waist = get_node("../Body")
export var controllable := true

var body := []

var variant := 1.0

var auto_balance_timeout := 0.0

onready var raycast = get_node("RayCast2D")
onready var pickup_zone = get_node("Pickup_range")

var float_height := 100.0 # The height at which the character should float
var float_force := 1000.0  # The force to apply when floating

var velocity := Vector2(0,0)

var stride
var stride_length := 0.5
var mult := 1.0
var run_dir := 1
var running  := false
var spine := []
var legs := []

var dead := false
var grabber
var upper_leg_keyframes := [
-1.0, 0, 2.4, 0
]

var lower_leg_keyframes := [
2.0, 1.0, 2.0, -1
]

var arm_collision_recovering := false

var jump := "arrow_up"
var crouch := "arrow_down"
var move_right := "arrow_right"
var move_left := "arrow_left"
var spin := "arrow_spin"

var proximity_threshold := deg2rad(45)
export var flip := false

func flip():
	
	new_desired_angle += deg2rad(180)
	
	for part in spine:
		part.new_desired_angle *= -1
	
	arm_collision_recovering = true



func set_color(body_color, limbs_color):
	var limb_style = spine1.get_node("Panel").get("custom_styles/panel")
	var body_style = get_node("Panel").get("custom_styles/panel")
	
	
	var eye_left_cover = get_node("Eye_Right/Whites/Eye_Cover")
	var eye_right_cover = get_node("Eye_Left/Whites/Eye_Cover")
	
	eye_right_cover.color = body_color
	eye_left_cover.color = body_color
	
	limb_style.set_bg_color(limbs_color)
	body_style.set_bg_color(body_color)



func _ready():
	
	grabber = spine1
	stride = 0.0
	body = [spine1, spine2, spine3, spine4, spine5, spine6, self, Leg_L_up, Leg_L_down, Leg_R_up, Leg_R_down]
	spine = [spine1, spine2, spine3, spine4, spine5, spine6]
	legs = [Leg_L_up, Leg_L_down, Leg_R_up, Leg_R_down]
	

	if flip:
		flip()

func interpolate_keyframes(keyframes, progress):
	var index = int(progress * len(keyframes))
	var t = progress * len(keyframes) - index
	var current_angle = keyframes[index % len(keyframes)]
	var next_angle = keyframes[(index + 1) % len(keyframes)]
	return lerp_angle(current_angle, next_angle, t)



func _input(event):
		
	if event.is_action_pressed(spin) and controllable:
		locked = false
		
		for part in spine:
			part.locked = false
#			part.get_node("PinJoint2D").softness = 1
			part.get_node("PinJoint2D").softness = 0
			part.set_collision_mask_bit(2, true)
			part.set_collision_layer_bit(1, true)
			part.set_collision_layer_bit(2, true) 

		spin_dir = run_dir*-1
		

#			print(grabbed_item)
#			scale.x = 2
		

	if event.is_action_released(spin) and controllable:
#		self.mode = RigidBody2D.MODE_CHARACTER
		if grabbed_item != null:
#			var test = str(grabbed_item)
#			print(test)
			grabbed_item.release()
			grabbed_item = null
			holding_something = false
			
			
		locked = true
		
		for part in spine:
			part.locked = true
			part.get_node("PinJoint2D").softness = 0
			

			part.set_collision_mask_bit(2, false)
			part.set_collision_layer_bit(1, false)
			part.set_collision_layer_bit(2, false) 
			
			bad_spines += 1
			
#			part.color_object.modulate = Color.red
			
		arm_collision_recovering = true
		
		spin_multiplier = 1
		
	
	if event.is_action_pressed(move_left):
		variant = 1
		mult = 1
		run_dir = 1
		
		if grabbed_item and grabbed_item != null and str(grabbed_item) != "[Deleted Object]":

#			grabbed_item.rotation = deg2rad(180)
			grabbed_item.new_desired_angle = deg2rad(180)
			
		
	if event.is_action_pressed(move_right):
		variant = 1
		mult = 1
		run_dir = -1
		
		if grabbed_item != null:
			grabbed_item.new_desired_angle = deg2rad(0)
	
	
	if event.is_action_released(jump) and raycast.is_colliding() and controllable:
		auto_balance_timeout = 0.5
		var change_power = (110-float_height)
		linear_velocity.y = 0
		

		self.apply_central_impulse(Vector2(0, jump_power*-1*(3+min(change_power/20, 5))))
		float_height = 100
	
	elif event.is_action_pressed(crouch) and controllable and !raycast.is_colliding():
		for part in legs:
				part.locked = true
		gravity_scale = 10
	
	
	if event.is_action_released(crouch) and controllable:
		for part in legs:
			part.locked = true
		float_height = 100  # Reset the float height when crouch is released.
		gravity_scale = 1

				
	
func _physics_process(_delta):
#	for thing in spine:
#		var joint = thing.get_node("PinJoint2D")
#		print(joint.bias)
#		joint.bias = 0.000
	
#	debugging, but i dont think its necessary...
	if str(grabbed_item) == "[Deleted Object]":
		grabbed_item = null

		if auto_balance_timeout <= 0:
			holding_something = false

	
	if Input.is_action_pressed(move_right) and controllable:
		variant += 0.001
		velocity.x = speed*variant
	
	elif Input.is_action_pressed(move_left) and controllable:		
		variant += 0.001
		velocity.x = -speed*variant
	
	else:
		velocity.x -= velocity.x/10


	if Input.is_action_pressed(spin) and controllable:
		spin_multiplier += 0.003
		angular_velocity = 10*spin_dir*min(spin_multiplier, 1.30)  # Set a constant angular velocity
		


	if velocity.length() > 10:
		running = true
	else:
		running = false
	
	
	power = 300
#	if locked:
#		var current_angle = get_global_transform().get_rotation() 
#		angular_velocity = lerp_angle(current_angle, new_desired_angle, (power) *_delta)


	if locked:
		var current_angle = get_global_transform().get_rotation()
		var angle_difference = abs(fmod((current_angle - new_desired_angle + PI), (2*PI)) - PI)
		if angle_difference > deg2rad(2.5):  # Adjust this value to change the size of the dead zone
			angular_velocity = lerp_angle(current_angle, new_desired_angle, (300)* _delta)
		else:
			angular_velocity = 0


	if running:
#		# Upper Leg power
		stride += mult * _delta
#		var new_power = abs(linear_velocity.x)
#		mult = min(2.5, new_power/400)
#
#		print(stride)
#		Leg_R_up.power = min(new_power, 400)
#		Leg_L_up.power = min(new_power, 400)


		# Upper Leg new desired angles
		Leg_R_up.new_desired_angle = interpolate_keyframes(upper_leg_keyframes, stride)*run_dir
		Leg_L_up.new_desired_angle = interpolate_keyframes(upper_leg_keyframes, stride + 0.5)*run_dir

		# Lower Leg new desired angles
		Leg_R_down.new_desired_angle = -interpolate_keyframes(lower_leg_keyframes, stride)*run_dir
		Leg_L_down.new_desired_angle = -interpolate_keyframes(lower_leg_keyframes, stride + 0.5)*run_dir

	else:
		Leg_R_up.new_desired_angle = deg2rad(15)
		Leg_L_up.new_desired_angle = deg2rad(-15)

		Leg_R_down.new_desired_angle = deg2rad(5)
		Leg_L_down.new_desired_angle = deg2rad(-5)

#	Making things point straight down:
	raycast.global_rotation = 0
	pickup_zone.global_rotation = 0
	

	if raycast.is_colliding() and auto_balance_timeout <= 0 and controllable:


#		Blimp code:
		var distance_to_ground = raycast.get_collision_point().distance_to(raycast.global_position)

		if (distance_to_ground < float_height) and !Input.is_action_pressed(crouch) and controllable:
#			chest_polygon.color = Color.red

			# Calculate the difference between the current height and the desired height
			var height_difference = float_height - distance_to_ground

			# Set the vertical velocity to a value proportional to the height difference
			self.linear_velocity.y = -height_difference * float_force/100

		elif (distance_to_ground > float_height+10) and !Input.is_action_pressed(crouch) and controllable:
#			chest_polygon.color = Color.yellow

			# Calculate the difference between the current height and the desired height
			var height_difference = distance_to_ground - float_height

			# Set the vertical velocity to a value proportional to the height difference
			self.linear_velocity.y = height_difference * float_force/100

	else:
		auto_balance_timeout -= (0.0166666666)
#		print(auto_balance_timeout)
	
	if Input.is_action_pressed(jump) and controllable and raycast.is_colliding():
#		self.mode = RigidBody2D.MODE_RIGID
		float_height = max(0, float_height-1)
		

	if arm_collision_recovering:
		for part in spine:
			if abs(part.current_angle - part.new_desired_angle) < proximity_threshold:
				part.set_collision_mask_bit(2, true)
				part.set_collision_layer_bit(1, true)
				part.set_collision_layer_bit(2, true) 
				bad_spines -= 1
#				part.color_object.modulate = Color.green
				
		if bad_spines <= 0:
			arm_collision_recovering = false

	var ground_velocity = Vector2.ZERO
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider.is_in_group("move_player"):
			ground_velocity = Vector2(collider.linear_velocity.x, -collider.linear_velocity.y)


	self.linear_velocity.x = velocity.x + ground_velocity.x
	
#	self.linear_velocity.x = velocity.x + ground_velocity.x
	self.linear_velocity.y += ground_velocity.y

	
var stabbed_bodies := []
var health := 1

func stabbed(body):
	stabbed_bodies.append(body)
	if stabbed_bodies.size() >= health:
		body.weight = 500
		get_node("Respawn_timer").start()
		ragdoll(5)
		
	
func _on_Respawn_timer_timeout():
	for body in stabbed_bodies:
		if str(body) != "[Deleted Object]":
			var test = str(body)
			body.queue_free()
			yield(body, "tree_exited")
	stabbed_bodies.clear()
	
	for part in body:
		locked = true
	
	controllable = true
	holding_something = false
	
	


func ragdoll(timeout):
	
	if timeout == 0:
		dead = false
	
	auto_balance_timeout = timeout

	
	for part in body:
		locked = false

	if grabbed_item:
		grabbed_item.release()
		grabbed_item = null
		holding_something = true


func die() -> void:
	ragdoll(9999999)
	SceneSwitcher.living_players -= 1
	SceneSwitcher.check_living()
	dead = true



func _on_Area2D_body_entered(body):
	if not body.get("usable") == null:
		if body.usable:
			if body.available and !holding_something and !body.held:
				body.target_node = grabber
				body.snap = true
				holding_something = true



