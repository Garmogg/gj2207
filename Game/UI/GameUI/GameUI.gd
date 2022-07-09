extends Control

func _ready():
	GameManager.game_ui_instance = self
	
	GameManager.connect("current_charge_updated", self, "_on_GameManager_current_charge_updated")

func update_stress(value):
	$StressBar.value = value
	
func update_lift(value):
	$PlaneLiftBar.value = value

func get_stress():
	return $StressBar.value
	
func get_lift():
	return $PlaneLiftBar.value
	
func _on_GameManager_current_charge_updated(val: float):
	$CurrentCharge.text = "Score: %f" % val
