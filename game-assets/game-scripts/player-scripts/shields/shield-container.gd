extends Node2D

onready var shield_paths : Array

var host : PlayerPhysics
signal shield_attached
signal shield_detached
var shield : Shield

func _on_host_ready(host_):
	set_process(false)
	host = host_
	shield_paths = AutoloadCharacters.shields_path
	#attach_shield(0)

var activated : bool = false

func attach_shield(s: int):
	if s < 0 or s >= shield_paths.size(): return
	if shield:
		if shield.shield_index == s:
			return
		if shield.is_connected("updatable_setted", self, "_on_Shield_Updatable_Setted"):
			shield.disconnect("updatable_setted", self, "_on_Shield_Updatable_Setted")
		shield.queue_free()
		shield = null
	var scene : PackedScene = load(shield_paths[s])
	var shield_to_attach : Shield = scene.instance()
	add_child(shield_to_attach)
	shield = shield_to_attach
	shield.connect("updatable_setted", self, "_on_Shield_Updatable_Setted")
	activated = true
	emit_signal("shield_attached")

func _on_Shield_Updatable_Setted(is_updating: bool) -> void:
	set_process(is_updating)

func _process(delta: float) -> void:
	if shield:
		shield.on_update(host, delta)

func detach_shield():
	activated = false
	shield.queue_free()
	shield = null
	emit_signal('shield_detached')
