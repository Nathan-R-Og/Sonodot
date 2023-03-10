extends FSM

func _enter_tree() -> void:
	set_physics_process(false)
	set_process_input(false)
	set_process(false)

func _ready() -> void:
	set_physics_process(false)
	set_process_input(false)
	set_process(false)

func get_current_state_node():
	if state_collection and state_collection.has_state(current_state):
		return state_collection.get_state(current_state)

func is_current_state(name:String) -> bool:
	return current_state == name

func _fsm_physics_process(delta):
	#print(current_state)
	var cur_state = get_current_state_node()
	if state_collection.has_state(current_state) and cur_state.is_state_physics_processing():
		if state_collection.has_state(current_state):
			cur_state.state_physics_process(host, delta)
			cur_state = get_current_state_node()
			
	if host.char_state_manager.is_valid_state(current_state):
		host.char_state_manager._middle_physics_process(host, delta, cur_state, current_state)
	
	host.prev_position = host.position


func _fsm_process(delta):
	var cur_state = get_current_state_node()
	if state_collection.has_state(current_state) and cur_state.is_state_processing():
		if state_collection.has_state(current_state):
			cur_state.state_process(host, delta)
			cur_state = get_current_state_node()
		
		if !host.play_specific_anim and cur_state.is_state_animation_processing():
			cur_state.state_animation_process(host, delta, host.animation)
		
	if host.char_state_manager.is_valid_state(current_state):
		host.char_state_manager._middle_process(host, delta, get_current_state_node(), current_state)
		cur_state = get_current_state_node()
		if !host.play_specific_anim:
			host.char_state_manager._middle_animation_process(host, delta, host.animation, cur_state, current_state)
	if host.player_camera:
		if host.player_camera.enabled:
			host.player_camera.camera_step(host, delta)

func change_state(state_name):
	assert(state_collection.has_state(state_name) or host.char_state_manager.is_valid_state(state_name), "Error: State %s does not exist in current context" % state_name)
	if state_name == current_state:
		return
	
	var cur_state = get_current_state_node()
	# Exit
	if state_collection.has_state(current_state):
		cur_state.state_exit(host, state_name)
		#cur_state.disconnect("finished", self, "change_state")
	if host.char_state_manager.is_valid_state(current_state):
		host.char_state_manager._middle_exit(host, state_name, cur_state, current_state)

	previous_state = current_state
	current_state = state_name
	
	cur_state = get_current_state_node()
	# Enter
	if state_collection.has_state(current_state):
		cur_state.connect("finished", self, "change_state", [], CONNECT_ONESHOT)
		cur_state.state_enter(host, previous_state)
	if host.char_state_manager.is_valid_state(current_state):
		host.char_state_manager._middle_enter(host, previous_state, get_current_state_node(), current_state)
	emit_signal('state_changed', previous_state, current_state, host)

func _fsm_input(event:InputEvent):
	var cur_state = get_current_state_node()
	if state_collection.has_state(current_state):
		cur_state.state_input(host, event)
	
	cur_state = get_current_state_node()
	if host.char_state_manager.is_valid_state(current_state):
		host.char_state_manager._middle_input(host, event, cur_state, current_state)
	
func _on_CharAnimation_animation_finished(anim_name: String) -> void:
	var cur_state = get_current_state_node()
	if state_collection.has_state(current_state):
		cur_state.state_animation_finished(host, anim_name)
		cur_state = get_current_state_node()
	if host.char_state_manager.is_valid_state(current_state):
		host.char_state_manager._middle_animation_finished(host, anim_name, cur_state, current_state)

func _on_Player_character_changed(previous_character, current_character):
	pass

func _on_Player_draw():
	var state = get_current_state_node()
	if state_collection.has_state(current_state):
		state.draw(host)
	if host.char_state_manager.is_valid_state(current_state):
		host.char_state_manager._middle_draw(host, state, current_state)
