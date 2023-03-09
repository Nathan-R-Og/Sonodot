extends State
#Idle

var slope : float

func state_enter(host : PlayerPhysics, prev_state):
	host.speed = Vector2.ZERO
	host.direction = Vector2.ZERO
	host.gsp = 0

func state_physics_process(host : PlayerPhysics, delta):
	var ground_angle = host.coll_handler.ground_angle()
	slope = -host.slp
	host.gsp += slope * sin(ground_angle)
	host.gsp -= min(abs(host.gsp), host.frc) * sign(host.gsp)
	if host.constant_roll:
		finish("Rolling")
		return
	if abs(host.gsp) > 0.1:
		finish("OnGround")
		return
	
	#print(host.coll_handler.fall_from_ground())
	if !host.is_ray_colliding or host.coll_handler.fall_from_ground() or !host.is_grounded:
		host.is_grounded = false
		host.snap_margin = 0
		#host.speed.y = 1
		#host.move_and_slide_preset()
		finish("OnAir")
		return
	
	if !host.can_fall or (abs(rad2deg(ground_angle)) <= 30):
		host.coll_handler.snap_to_ground()
		host.speed = Vector2.ZERO
		return
	
	#host.speed.x = host.gsp * cos(ground_angle)
	#host.speed.y = host.gsp * -sin(ground_angle);

func state_animation_process(host, delta:float, animator: CharacterAnimator):
	animator.animate('Idle', 1.0, true)

func state_input(host, event):
	if host.direction != Vector2.ZERO:
		if host.direction.x != 0:
			finish("OnGround")
			return
		if host.direction.y > 0:
			if host.gsp > host.min_to_roll:
				finish("Rolling")
				return
			finish("Crouch")
			return
		else:
			finish("LookUp")
			return
	if event.is_action_pressed('ui_jump_i%d' % host.player_index):
		finish(host.jump())
