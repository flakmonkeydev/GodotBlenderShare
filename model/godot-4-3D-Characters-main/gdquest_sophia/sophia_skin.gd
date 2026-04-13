@tool
extends  Node3D
@export var linger_time: float = 2.0
@export var mesh: MeshInstance3D
@export var animation_tree: AnimationTree

func motion_freeze() -> void:
	var tween = create_tween().set_parallel(true)
	tween.tween_property(animation_tree, "parameters/TimeScaleIdle/scale", 0.0001, linger_time).set_ease(Tween.EASE_IN)
	tween.tween_property(animation_tree, "parameters/TimeScaleRun/scale", 0.0001, linger_time).set_ease(Tween.EASE_IN)
	#tween.tween_property(animation_tree, "active", false, linger_time * 1.25)
func motion_unfreeze() -> void:
	var tween = create_tween().set_parallel(true)
	#tween.tween_property(animation_tree, "active", true, 0.01)
	tween.tween_property(animation_tree, "parameters/TimeScaleIdle/scale", 1.0, linger_time).set_ease(Tween.EASE_OUT)
	tween.tween_property(animation_tree, "parameters/TimeScaleRun/scale", 1.0, linger_time).set_ease(Tween.EASE_OUT)
	
