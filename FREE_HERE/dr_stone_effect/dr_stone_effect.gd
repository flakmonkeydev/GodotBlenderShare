@tool
extends Node3D
@export var character: Node3D

@export var is_idle: bool = false:
	set(val):
		is_idle = val
		if is_idle:
			character.animation_tree.set("parameters/Transition/transition_request", "state_0")
		else:
			character.animation_tree.set("parameters/Transition/transition_request", "state_1")
@export var effect_edge: bool = false:
	set(val):
		effect_edge = val	
		if effect_edge:
			character.mesh.set_instance_shader_parameter("edge_mode", 1)
		else:
			character.mesh.set_instance_shader_parameter("edge_mode", 0)
			

@export var stone_effect: bool = false:
	set(val):
		stone_effect = val
		if val == true:
			freeze()
		else:
			unfreeze()

		
func freeze() -> void:
	character.motion_freeze()
	var tween = create_tween()
	tween.tween_property(character.mesh, "instance_shader_parameters/dissolve_amount", 0.0, character.linger_time)


func unfreeze() -> void:
	character.motion_unfreeze()
	var tween = create_tween()
	tween.tween_property(character.mesh, "instance_shader_parameters/dissolve_amount", 1.0, character.linger_time)
