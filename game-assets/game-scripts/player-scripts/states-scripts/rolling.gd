extends State

var slope : float
var idle_anim = 'Rolling'

func state_enter(host, prev_state):
	host.is_pushing = false
	idle_anim = 'Rolling'
	host.snap_margin = host.snaps
	host.suspended_jump = false
	host.audio_player.play("spin")
	

func state_physics_process(host: PlayerPhysics, delta):
	var gsp_dir = sign(host.gsp)
	var abs_gsp = abs(host.gsp)
	var coll_handler = host.coll_handler
	var m_handler = host.m_handler
	
	if abs_gsp < .1 and host.direction.x == 0:
		finish("Idle")
		return
	
	if !host.is_grounded or host.is_floating:
		host.is_grounded = false
		host.snap_margin = 0
		finish("OnAir")
		return
	
	if !host.is_ray_colliding or coll_handler.fall_from_ground():
		host.is_grounded = false
		host.snap_margin = 0
		finish("OnAir")
		return
	#print(rad2deg(ground_angle))
	
	if abs_gsp <= 67.875:
		if !host.constant_roll:
			finish("OnGround")
			return
	
	m_handler.handle_rolling_motion()
	
	var ground_angle = coll_handler.ground_angle()
	abs_gsp = abs(host.gsp)
	gsp_dir = sign(host.gsp)
	
	if coll_handler.is_pushing_wall():
		host.gsp = 0.0
		finish("OnGround")
		return
	
	host.speed.x = host.gsp * cos(ground_angle)
	host.speed.y = host.gsp * -sin(ground_angle)
	
	if !host.can_fall || (abs(rad2deg(ground_angle)) <= 30 && host.rotation != 0):
		coll_handler.snap_to_ground()

func state_exit(host, next_state):
	if next_state == "OnAir":
		host.rotation = 0
		host.character.rotation = 0
		host.sprite.offset = Vector2.ONE * -15

func state_animation_process(host, delta:float, animator: CharacterAnimator):
	var anim_name = idle_anim
	var anim_speed = 1.0
	var coll_handler = host.coll_handler
	var m_handler = host.m_handler
	
	var abs_gsp = abs(host.gsp)
	var gsp_dir = sign(host.gsp)
	
	var ground_angle = coll_handler.ground_angle()
	
	# Calculate sprite offset
	var center = Vector2(-16, -15)
	var offset = Vector2(sin(ground_angle), cos(ground_angle))
	var offset_max = Vector2(5 * host.side, 5)
	
	# Set sprite offset when rolling
	host.sprite.offset = \
		center + offset * offset_max
		
	anim_name = 'Rolling'
	anim_speed = -((5.0 / 60.0) - (abs_gsp / 120.0))
	
	var abs_crot = abs(host.character.rotation)
	host.character.rotation += (-host.character.rotation) * (2 * delta)
	host.character.rotation = 0
	anim_speed = max(-(8.0 / 60.0 - (abs_gsp / 120.0)), 1.6)
	if gsp_dir != 0:
		host.character.scale.x = gsp_dir

	animator.animate(anim_name, anim_speed);

func _on_CharAnimation_animation_finished(anim_name):
	pass

func state_input(host, event):
	if event.is_action_pressed("ui_jump_i%d" % host.player_index):
		finish(host.jump())
