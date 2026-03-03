@tool
extends Node3D
@export var mesh: MeshInstance3D
@export var particle: GPUParticles3D
@export var duration: float = 1.5:
	set(val):
		duration = val
		particle.lifetime = val

@export var disintegrate: bool = false:
	set(val):
		disintegrate = val
		_disintegrate(val)
		
func _disintegrate(val: bool) -> void:
	if mesh and particle:
		var tween = create_tween()
		if val:
			tween.tween_property(mesh, "instance_shader_parameters/dissolve_amount", 1.1, duration).set_ease(Tween.EASE_IN)
			await get_tree().create_timer(duration / 3.0).timeout
			particle.visible = true
			particle.emitting = true
		else:
			tween.tween_property(mesh, "instance_shader_parameters/dissolve_amount", -0.1, 0.1)
			particle.visible = false
			particle.restart()
			particle.emitting = false
