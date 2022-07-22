extends Spatial

onready var main_camera : Camera = $MainCamera
onready var sequence_camera : Camera = $SequenceCamera
onready var main_cam_y_pos : float = main_camera.translation.y
onready var sequence_cam_y_pos : float = sequence_camera.translation.y

# Confronting stuff
onready var opponent1_pos : Spatial = $Oppenent1Pos
onready var opponent2_pos : Spatial = $Oppenent2Pos

onready var button_smasher : ButtonSmasher = $ButtonMasher

var player : Player = null
var opponent : Spatial = null

onready var opponent_last_pos : Transform = opponent2_pos.global_transform

var confronting : bool = false

var base_strength : float = 30
var base_loss : float = 30
var base_press_strength : float = 10

var strength : float = base_strength
var loss : float = base_loss
var press_strength : float = base_press_strength

# Luggage throwing stuff

var luggage_throwing : bool = false


var timer : Timer
var anim

var cur_time = 0
func camera_tremble( camera : Camera ):
	var pm = GameManager.progression_manager_instance;
	var intensity = 1 + pm.inclination[0]
	camera.translation.y += sin( cur_time * 10  ) * 0.001 * intensity
	camera.translation.y += sin( cur_time * -20  ) * 0.002 * intensity
	camera.translation.x += cos( cur_time * 10  ) * 0.001 * intensity
	camera.translation.x += cos( cur_time * -70  ) * 0.002 * intensity
	camera.translation.z += cos( cur_time * -30  ) * 0.001 * intensity

func _ready():
	timer = Timer.new()
	timer.one_shot = true
	
	add_child(timer)
	anim = get_parent().get_node("AircraftCabin").get_node("Door").get_node("AnimationPlayer")
	
	var _ret = timer.connect("timeout", self, "on_timeout")

func _process(delta):
	cur_time += delta
	if confronting or luggage_throwing:
		camera_tremble( sequence_camera )
	else:
		camera_tremble( main_camera )
	if confronting:
		strength -= loss * delta
		if Input.is_action_just_pressed("grab_passenger"):
			strength += press_strength
		button_smasher.set_value(strength)
		
		if strength <= 0.0 || strength >= 100.0:
			if strength <= 0.0:
				player.queue_free()
				GameManager.game_over()
				player = null
			else:
				var luggage_weight = 0
				if(opponent.luggage != null):
					luggage_weight = opponent.luggage.settings["weight"]
					opponent.luggage.eject()
					get_parent().get_node("AircraftCabin/EjectionTrajectory").eject(opponent.luggage, false)
					opponent.luggage = null
				opponent.eject()
				get_parent().get_node("AircraftCabin/EjectionTrajectory").eject(opponent, true)
				GameManager.object_thrown(opponent.weight + luggage_weight)
				GameManager.update_passenger_angry()
				opponent = null
			
			stop_confront()

func confront(p_player : Spatial, p_opponent : Spatial) -> void:
	player = p_player
	opponent = p_opponent
	
	confronting = true
	
	main_camera.current = false
	sequence_camera.current = true
	
	button_smasher.visible = true
	
	strength = base_strength
	loss = base_loss * opponent.strength
	
	opponent_last_pos = opponent.global_transform
	
	player.global_transform = opponent1_pos.global_transform
	opponent.global_transform = opponent2_pos.global_transform
	main_camera.translation.y = main_cam_y_pos
	
	timer.start(10.0)
	
	anim.play("open")
	$OutsideSound.play()
	
	opponent.get_child(1).get_child(0).play_animation("Confrontation")

func throw_luggage(p_player : Spatial):
	luggage_throwing = true
	main_camera.current = false
	sequence_camera.current = true
	anim.play("open")
	$OutsideSound.play()
	player = p_player
	timer.start(1.0)
	player.global_transform = opponent1_pos.global_transform
	main_camera.translation.y = main_cam_y_pos

func stop_throw_luggage():
	anim.play("Close")
	$OutsideSound.stop()
	main_camera.current = true
	sequence_camera.current = false
	luggage_throwing = false
	if player != null:
		player.confronting = false
		player = null
	sequence_camera.translation.y = sequence_cam_y_pos

func stop_confront():
	anim.play("Close")
	$OutsideSound.stop()
	confronting = false
	
	if player != null:
		player.stop_confrontation()
		player = null
	
	if opponent != null:
		opponent.global_transform = opponent_last_pos
		opponent.get_child(1).get_node("CharacterModel").force_play_animation("Sitting")
		opponent = null
	
	button_smasher.visible = false
	main_camera.current = true
	sequence_camera.current = false
	sequence_camera.translation.y = sequence_cam_y_pos
	
	timer.stop()

func on_timeout():
	if confronting:
		stop_confront()
	if luggage_throwing:
		stop_throw_luggage()

func _on_ProgressionManager_inclination_updated(val):
	var current_camera
	if confronting or luggage_throwing:
		current_camera = sequence_camera
	else:
		current_camera = main_camera
	current_camera.rotation.z = deg2rad(min(5, val) * 5)
