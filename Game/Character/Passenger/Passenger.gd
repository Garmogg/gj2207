extends Spatial
class_name Passenger

signal ejected(passenger)

var speed: float
var strength: float
var saved_strength: float
var fear_multiplicator: float
var anger_multiplicator: float
var protectiveness: float
var saved_protectiveness: float
var weight: float
var luggage_ejectable : bool = true
var luggage: Luggage = null
var timer:Timer
var tried : bool = false

var anger: float = 0.5
var fear: float = 0.5

func add_anger(_anger):
	anger += _anger * anger_multiplicator

func add_fear(_fear):
	fear += _fear * fear_multiplicator

func set_speed(_speed):
	speed = _speed

func set_strength(_strength):
	strength = _strength
	saved_strength = strength

func set_fear_multiplicator(_fear):
	fear_multiplicator = _fear
	
func set_anger_multiplicator(_anger):
	anger_multiplicator = _anger
	
func set_fear(_fear):
	fear = _fear
	
func set_anger(_anger):
	anger = _anger
	
func set_protectiveness(_protector):
	protectiveness = _protector
	saved_protectiveness = protectiveness

func set_weight(_weight):
	weight = _weight

func set_luggage(_luggage):
	luggage = _luggage

func get_speed():
	return speed

func get_strength():
	return strength

func get_fear_multiplicator():
	return fear_multiplicator
	
func get_anger_multiplicator():
	return anger_multiplicator

func get_fear():
	return fear
	
func get_anger():
	return anger
	
func get_protectiveness():
	return protectiveness
	
func get_weight():
	return weight
	
func _ready():
	GameManager.register_passenger(self)
	
	timer = Timer.new()
	
	add_child(timer)
	
	var _ret = timer.connect("timeout", self, "on_timeout")

func _process(delta):
	var rand_val = randi() % 100 * anger_multiplicator
	var rand_val2 = randi() % 100 * fear_multiplicator
	if(rand_val < 75 ) :
		update_anger(delta)
	if(rand_val2 < 75) :
		update_fear(delta)

func eject():
	emit_signal("ejected", self)

func update_anger(delta):
	var rand_val = randf()
	if(fear < 0.9):
		if(anger>0.9) :
			luggage_ejectable = false
			strength = saved_strength * 2
		else:
			luggage_ejectable = true
			strength = saved_strength
	if(anger >1) :
		anger = 1
	if(anger >0) :
		anger -= (rand_val / anger_multiplicator) * delta * 0.001
	
func update_fear(delta):
	var rand_val = randf()
	if(fear>0.9) :
		protectiveness = 0
		strength = saved_strength / 2
	else:
		if(anger < 0.9):
			protectiveness = saved_protectiveness
			strength = saved_strength
	if(fear >1) :
		fear = 1
	if(fear>0) :
		fear -= (rand_val / fear_multiplicator) * delta * 0.001
	
func ejected_passenger():
	var rand_val_anger = randi() % 100 * anger_multiplicator
	var rand_val_fear = randi() % 100 * fear_multiplicator
	if(rand_val_anger > 70 ) :
		var rand_val = min(randf() + 0.2 , 0.6)
		anger += (rand_val * anger_multiplicator) * 0.05
	elif(rand_val_fear > 70 ) :
		var rand_val = min(randf() + 0.2 , 0.6)
		fear += (rand_val * fear_multiplicator) * 0.05

func ejected_luggage():
#	if(!tried):
#		timer.start(5.0)
#		tried = true
#	else:
#		return false

	if luggage == null:
		return false

#	var randProtect = randi() % 100 * protectiveness
	var rand_val_anger = randi() % 100 * anger_multiplicator
	var rand_val_fear = randi() % 100 * fear_multiplicator
	if(rand_val_anger > 70 ) :
		var rand_val = min(randf() + 0.2 , 0.6)
		anger += (rand_val * fear_multiplicator) * 0.03
	elif(rand_val_fear > 70 ) :
		var rand_val = min(randf() + 0.2 , 0.6)
		fear += (rand_val * fear_multiplicator) * 0.03 
#	if(luggage_ejectable && randProtect < 50):
	GameManager.object_thrown(luggage.settings["weight"])
	GameManager.level.get_node("AircraftCabin/EjectionTrajectory").eject(luggage, false)
	luggage.eject()
	return true
#		return true
#	else :
#		return false

func on_timeout():
	tried = false

func _on_Area_body_entered(body):
	if body as Player:
		body.add_near_passenger(self)

func _on_Area_body_exited(body):
	if body as Player:
		body.remove_near_passenger(self)
