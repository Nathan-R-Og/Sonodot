extends StateChar


func state_input(host : PlayerPhysics, event: InputEvent, main_state:State = null):
	if event is InputEventKey:
		if event.is_action_pressed('ui_jump_i%d' % host.player_index):
			finish('SuperPeelOut')
