class_name Player
extends KinematicBody

const CONTROLLER_DEADZONE = 0.2

const CONTROL_MODE_KEYBOARD : int = 0
const CONTROL_MODE_CONTROLLER : int = 1

var control_mode := CONTROL_MODE_KEYBOARD

var confronting := false

var move_speed : float = 3.0

var velocity : Vector3 = Vector3.ZERO

var near_passengers := []

onready var throw_button : Sprite = $ThrowButton

var walk_start_delay = 0.15
var walk_spacing = 0.47
var walk_current_delta = walk_start_delay

func _ready():
	$CharacterModel.play_animation("Idle")

func _physics_process(_delta : float) -> void:
	if confronting:
		return
	
	move(_delta)
	
	grab_passenger()

func get_nearest_passenger() -> Spatial:
	if near_passengers.empty():
		return null
	
	var nearest_passenger : Spatial = near_passengers[0]
	var nearest_distance : float = INF
	
	for passenger in near_passengers:
		var dist :=  global_transform.origin.distance_squared_to(passenger.global_transform.origin)
		if dist < nearest_distance:
			nearest_passenger = passenger
			nearest_distance = dist
			
		
	return nearest_passenger

func grab_passenger() -> void:
	var nearest_passenger := get_nearest_passenger()
	
	throw_button.visible = nearest_passenger != null
	
	if nearest_passenger:
		var passenger_pos : Vector3 = nearest_passenger.global_transform.origin
		var pos2d : Vector2 = get_viewport().get_camera().unproject_position(passenger_pos + Vector3.UP * 1.8)
		
		throw_button.position = pos2d
		
		if Input.is_action_just_pressed("grab_passenger"):
			get_tree().call_group("SequenceManager", "confront", self, nearest_passenger)
			confrontation_transition()
		elif Input.is_action_just_pressed("grab_luggage") and nearest_passenger.luggage != null:
			get_tree().call_group("SequenceManager", "throw_luggage", self )
			if nearest_passenger.ejected_luggage(): 
				luggage_transition()

	

func confrontation_transition():
	throw_button.visible = false
	confronting = true
	$CharacterModel.play_animation("Confrontation")

func luggage_transition():
	throw_button.visible = false
	confronting = true
	$CharacterModel.play_animation("LuggageThrow")

func move(delta) -> void:
	var input_dir = Input.get_vector(
		"move_left", "move_right", 
		"move_backward", "move_forward",
		CONTROLLER_DEADZONE
	)
	
	var move_dir : Vector3
	
	if control_mode == CONTROL_MODE_CONTROLLER:
		var cam_forward : Vector3 = -get_viewport().get_camera().global_transform.basis.z
		var cam_right : Vector3 = get_viewport().get_camera().global_transform.basis.x
		move_dir = input_dir.x * cam_right + input_dir.y * cam_forward
		move_dir = Vector3(move_dir.x, 0, move_dir.z)
		if !move_dir.is_equal_approx(Vector3.ZERO):
			move_dir = move_dir.normalized()
	else:
		move_dir = Vector3(-input_dir.x, 0, input_dir.y)
	
	if !move_dir.is_equal_approx(Vector3.ZERO):
		velocity = move_and_slide(move_dir * move_speed)
		look_at(global_transform.origin + move_dir, Vector3.UP)
		$CharacterModel.play_animation("Walk")
		if walk_current_delta <= 0:
			$WalkSound.play()
			walk_current_delta = walk_spacing
		else:
			walk_current_delta -= delta
	else:
		walk_current_delta = walk_start_delay
		$CharacterModel.play_animation("Idle")

func _input(event : InputEvent) -> void:
	if ((event is InputEventJoypadButton) or 
		(event is InputEventJoypadMotion and event.axis_value > CONTROLLER_DEADZONE)):
		control_mode = CONTROL_MODE_CONTROLLER
	elif (event is InputEventKey) or (event is InputEventMouseButton):
		control_mode = CONTROL_MODE_KEYBOARD

func add_near_passenger(passenger : Spatial) -> void:
	near_passengers.append(passenger)

func remove_near_passenger(passenger : Spatial) -> void:
	near_passengers.erase(passenger)
