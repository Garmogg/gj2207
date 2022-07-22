extends Spatial

signal push_ended

onready var anim_tree = $AnimationTree

onready var luggages = $CharacterModelNormal_export/Armature/Skeleton/BoneAttachment/Luggages

func _ready():
	set_luggages_not_visible()

func play_animation(name : String):
	anim_tree.get("parameters/playback").travel(name)
	
func force_play_animation(name : String):
	anim_tree.get("parameters/playback").start(name)

func set_luggage_visible(idx : int) -> void:
	for child_idx in range(0, luggages.get_child_count()):
		luggages.get_child(child_idx).visible = (child_idx == idx)

func set_luggages_not_visible():
	for child in luggages.get_children():
		child.visible = false
