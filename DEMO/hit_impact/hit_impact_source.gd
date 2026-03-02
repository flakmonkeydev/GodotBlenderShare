@tool
extends Node3D
class_name HitImpact

@onready var flare: GPUParticles3D = %Flare
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var shockwave: GPUParticles3D = %Shockwave
@onready var particles: GPUParticles3D = %Particles
var is_ready: bool = false

func _ready() -> void:
	is_ready = true

@export_range(0.0, 15.0, 1.0) var flare_texture_index:
	set(val):
		flare_texture_index = val
		set_texture_index(flare, val)
@export_range(0.0, 15.0, 1.0) var shockwave_texture_index:
	set(val):
		shockwave_texture_index = val
		set_texture_index(shockwave, val)
@export_range(0.0, 15.0, 1.0) var particle_texture_index:
	set(val):
		particle_texture_index = val
		set_texture_index(particles, val)
				
@export var flare_color: Color:
	set(val):
		flare_color = val
		set_manual_color(flare, val)

@export var shockwave_color: Color:
	set(val):
		shockwave_color = val
		set_manual_color(shockwave, val)

@export var particle_color: Color:
	set(val):
		particle_color = val
		set_manual_color(particles, val)

@export_tool_button("Start") var start_emit = _start_emit

func _start_emit() -> void:
	if is_ready:
		animation_player.play("start")

func set_texture_index(node: GPUParticles3D, index: float) -> void:
	if is_ready:
		node.set_instance_shader_parameter("texture_index", index)
	
func set_manual_color(node: GPUParticles3D, manual_color: Color) -> void:
	if is_ready:
		node.set_instance_shader_parameter("manual_color", manual_color)
