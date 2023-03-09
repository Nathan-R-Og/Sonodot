extends KinematicBody2D

var players : Array = [] setget set_players
onready var animator = $Sprite/AnimationPlayer
onready var area : Area2D = $Area2D

class PinballLeverState extends State:
	
	var center_point : Vector2 = Vector2.ZERO
	var current_lever : KinematicBody2D
	
	func state_enter(host, prev_state):
		host.constant_roll = true
		host.boost_constant_roll = false
	
	func state_physics_process(host : PlayerPhysics, delta):
		#print(current_lever.scale.x)
		#center_point.y = -1.5 * host.global_position.distance_to(current_lever.global_position)
		#center_point.x = -2* host.global_position.distance_to(current_lever.global_position) + 64
		
		current_lever.update()
		if !host.is_grounded:
			host.speed.y += host.grv
			return
		
		host.m_handler.handle_rolling_motion()
		
		var ground_angle = host.coll_handler.ground_angle();
		
		var gsp_dir = sign(host.gsp)
		var abs_gsp = abs(host.gsp)
		
		host.speed.x = host.gsp * cos(ground_angle)
		host.speed.y = host.gsp * -sin(ground_angle)
		
		if !host.can_fall or (abs(rad2deg(ground_angle)) <= 30 and host.rotation != 0):
			host.coll_handler.snap_to_ground()
		
	
	func state_animation_process(host, delta, animator):
		animator.animate("Rolling")
		host.character.rotation = 0
		host.sprite.offset = \
		Vector2(-16, -15) + \
		(Vector2(sin(host.character.rotation), cos(host.character.rotation)) *\
		Vector2(5 * host.side, 5))
	
	func state_input(host : PlayerPhysics, event):
		if Input.is_action_just_pressed("ui_jump_i%d" % host.player_index):
			var global_circle_center = current_lever.global_position + center_point
			#var r = host.global_position.distance_to(global_circle_center)
			#var angle_to_push = global_circle_center.angle_to(host.global_position)
			var m = (-(host.global_position.y - global_circle_center.y) / -(host.global_position.x - global_circle_center.x))
			
			#var yyo = m * (global_circle_center.x - host.global_position.x)
			#var yyo_vec = Vector2(cos(yyo), sin(yyo))
			#host.speed = yyo_vec * host.jmp * 2.25
			var pos_local = current_lever.to_local(host.position)
			var distance = Vector2.ZERO.distance_to(pos_local)
			var force = (distance / 57.4) - .5
			host.speed.x = distance * (force * 25)
			host.speed.y = distance * 15
			#print(host.speed)
			host.speed.x = host.speed.x * current_lever.scale.y
			host.speed.y = -abs(host.speed.y)
			host.is_grounded = false
			host.snap_margin = 0
			host.move_and_slide_preset()
			current_lever.animator.play("Move")
			host.fsm.erase_state(name, "OnAir")
	
	func state_exit(host, event):
		host.constant_roll = false
		host.sprite.rotation = 0
		current_lever.update()
	
	func when_player_exit_from_lever(body):
		if body is PlayerPhysics:
			body.fsm.erase_state(name)

	func draw_external(host):
		if !host.fsm.is_current_state(name): return
		var p = current_lever.to_local(host.position)
		current_lever.draw_circle(center_point, center_point.distance_to(p), Color(0xff0000aa))
		current_lever.draw_circle(p.normalized() * p.length(), 20, Color(0xff0000aa))
		

func _on_Area2D_body_entered(body):
	if body is PlayerPhysics:
		if body.position.y >= position.y: return
		var p : PlayerPhysics = body
		p.erase_state()
		var lever_state:PinballLeverState = PinballLeverState.new()
		area.connect("body_exited", lever_state, "when_player_exit_from_lever")
		connect("draw", lever_state, "draw_external", [p])
		players.append(p)
		p.fsm.insert_state(lever_state)
		lever_state.current_lever = self

func set_players(val : Array) -> void:
	players = val
	if players.size() > 0:
		set_process_input(true)
		set_physics_process(true)
	else:
		set_process_input(false)
		set_physics_process(false)

func _on_Area2D_body_exited(body):
	if body is PlayerPhysics:
		players.remove(players.find(body))

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Move":
		animator.play("RESET")
