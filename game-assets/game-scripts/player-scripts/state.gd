extends Node
class_name State

signal finished(next_state)

var _state_processing : bool = true setget set_state_processing, is_state_processing
var _state_physics_processing: bool = true setget set_state_physics_processing, is_state_physics_processing
var _state_processing_anim: bool = true setget set_state_animation_processing, is_state_animation_processing

func set_state_processing(val : bool) -> void: _state_processing = val
func is_state_processing() -> bool: return _state_processing

func set_state_physics_processing(val : bool) -> void: _state_physics_processing = val
func is_state_physics_processing() -> bool: return _state_physics_processing

func set_state_animation_processing(val : bool) -> void: _state_processing_anim = val
func is_state_animation_processing() -> bool: return _state_processing_anim

#end, goto
func finish(next_state: String): emit_signal("finished", next_state)

func state_enter(host, prev_state:String):pass
func state_exit(host, next_state:String):pass

func state_physics_process(host, delta:float):pass
func state_process(host, delta:float): pass

func state_animation_process(host, delta:float, animator:CharacterAnimator):pass
func state_animation_finished(host, anim_name: String):pass
func state_animation_started(host, anim_name: String):pass
func state_animation_changed(host, old_name:String, new_name:String):pass

func state_input (host, event : InputEvent):pass

func get_class(): return "State"
func is_class(name:String): return get_class() == name || .is_class(name)

func draw(host):pass
