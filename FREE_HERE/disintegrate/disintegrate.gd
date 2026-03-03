@tool
extends Node3D
@export var meshes: Array[MeshInstance3D]
@export var particles: Array[GPUParticles3D]
@export var delay_emit_time: float = 0.5


@export var duration: float = 1.5:
	set(val):
		duration = val
		for particle in particles:
			particle.lifetime = val

@export var disintegrate: bool = false:
	set(val):
		disintegrate = val
		_disintegrate(val)
		
func _disintegrate(val: bool) -> void:
	if meshes and particles:
		for mesh: MeshInstance3D in meshes:
			var tween = create_tween().set_parallel(true)
			if val:
				tween.tween_property(mesh, "instance_shader_parameters/dissolve_amount", 1.1, duration).set_ease(Tween.EASE_OUT)
				for particle in particles:
					tween.tween_property(particle, "visible", true, 0.05).set_delay(delay_emit_time)
					tween.tween_property(particle, "emitting", true, 0.05).set_delay(delay_emit_time)

			else:
				tween.tween_property(mesh, "instance_shader_parameters/dissolve_amount", -0.1, 0.1)
				for particle in particles:
					particle.visible = false
					particle.restart()
					particle.emitting = false
