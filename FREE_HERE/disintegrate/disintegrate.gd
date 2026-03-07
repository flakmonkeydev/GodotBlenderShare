@tool
extends Node3D
@export var meshes: Array[MeshInstance3D]
@export var particles: Array[GPUParticles3D]
@export var delay_emit_time: float = 0.5
@export var mat_model: Material
@export var mat_invi: Material

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
				tween.tween_property(mesh, "instance_shader_parameters/outline_active", false, 0.05).set_ease(Tween.EASE_OUT)
				for particle in particles:
					tween.tween_property(particle, "visible", true, 0.05).set_delay(delay_emit_time)
					tween.tween_property(particle, "emitting", true, 0.05).set_delay(delay_emit_time)

			else:
				tween.tween_property(mesh, "instance_shader_parameters/dissolve_amount", -0.1, 0.1)
				tween.tween_property(mesh, "instance_shader_parameters/outline_active", true, 0.05).set_ease(Tween.EASE_OUT)
				for particle in particles:
					particle.visible = false
					particle.restart()
					particle.emitting = false


@export var glitch: bool = false:
	set(val):
		glitch = false
		_glitch()
		
func _glitch() -> void:
	if meshes and particles:
		for mesh: MeshInstance3D in meshes:
			var tween = create_tween().set_parallel(true)
			tween.tween_property(mesh, "instance_shader_parameters/glitch_strength", 0.3, 0.01)
			tween.tween_property(mesh, "instance_shader_parameters/outline_active", true, 0.01)
			tween.tween_property(mesh, "instance_shader_parameters/glitch_strength", 0.0, 0.01).set_delay(0.25)

@export var glitch_and_flash: bool = false:
	set(val):
		glitch_and_flash = false
		_glitch_and_flash()
		
func _glitch_and_flash() -> void:
	if meshes and particles:
		for mesh: MeshInstance3D in meshes:
			var tween = create_tween().set_parallel(true)
			tween.tween_property(mesh, "instance_shader_parameters/glitch_strength", 0.3, 0.01)
			tween.tween_property(mesh, "instance_shader_parameters/flash_strength", 10, 0.01)
			tween.tween_property(mesh, "instance_shader_parameters/outline_active", true, 0.01)
			tween.tween_property(mesh, "instance_shader_parameters/glitch_strength", 0.0, 0.01).set_delay(0.3)
			tween.tween_property(mesh, "instance_shader_parameters/flash_strength", 0.0, 0.01).set_delay(0.3)

@export var invi: bool = false:
	set(val):
		invi = val
		_invi(val)
		
func _invi(val: bool) -> void:
	if meshes and particles:
		if val:
			for mesh: MeshInstance3D in meshes:
				mesh.set_instance_shader_parameter("flash_color", Vector3(0.5, 0.9, 1.0))
				var tween = create_tween().set_parallel(true)
				tween.tween_property(mesh, "instance_shader_parameters/flash_strength", 5, 0.01)
				tween.tween_property(mesh, "instance_shader_parameters/flash_strength", 0, 0.39).set_trans(Tween.TRANS_EXPO).set_delay(0.05)
				tween.tween_property(mesh, "instance_shader_parameters/glitch_strength", 0.3, 0.01)
				tween.tween_property(mesh, "instance_shader_parameters/glitch_strength", 0.0, 0.01).set_delay(0.3)
			await get_tree().create_timer(0.4).timeout
			for mesh: MeshInstance3D in meshes:
				mesh.material_override = mat_invi
				mesh.set_instance_shader_parameter("invisibility_level", 0.0)
				var tween = create_tween().set_parallel(true)
				tween.tween_property(mesh, "instance_shader_parameters/invisibility_level", 0.9, 0.75).set_ease(Tween.EASE_IN)
		else:
			for mesh: MeshInstance3D in meshes:
				var tween = create_tween().set_parallel(true)
				tween.tween_property(mesh, "instance_shader_parameters/invisibility_level", 0.0, 0.75).set_ease(Tween.EASE_OUT)
			await get_tree().create_timer(0.4).timeout
			for mesh: MeshInstance3D in meshes:
				mesh.material_override = mat_model
				mesh.set_instance_shader_parameter("dissolve_mode", 0)
				mesh.set_instance_shader_parameter("noise_scale", Vector2(5,5))
				mesh.set_instance_shader_parameter("noise_layer_index", 14)
			
