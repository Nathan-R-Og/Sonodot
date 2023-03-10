extends State

#var slope : float
var is_braking : bool
var brake_sign : int
var idle_anim = 'Idle'
var brake_time = 0.0

func state_enter(host, prev_state):
	host.is_pushing = false
	#idle_anim = 'Idle'
	host.snap_margin = host.snaps
	host.suspended_jump = false
	

func state_physics_process(host : PlayerPhysics, delta):
	#print("test")
	var coll_handler = host.coll_handler
	var m_handler = host.m_handler
	var ground_angle = coll_handler.ground_angle()
	
	#if total groundspeed == 0
	#and no specific direction
	###happens when landing while holding neutral with no velocity
	###(jumping in place basically)
	if abs(host.gsp) == 0 && host.direction.x == 0:
		#set idle
		finish("Idle")
		return
	
	#if rays aren't colliding
	#or falling from ground
	#or floating
	###happens mainly when falling off a ledge
	if not host.is_ray_colliding or coll_handler.fall_from_ground() or host.is_floating:
		#set not grounded
		host.is_grounded = false
	if not host.is_grounded:
		host.snap_margin = 0
		finish("OnAir")
		return
	
	m_handler.handle_ground_motion()
	ground_angle = coll_handler.ground_angle()
	var gsp_dir = sign(host.gsp)
	var abs_gsp = abs(host.gsp)
	#if
	###direction.x and -gsp_dir are both zero, or holding against your speed
	if host.direction.x == -gsp_dir:
		#if total gsp == 0
		if abs_gsp == 0:
			#set to (zero) dec * direction.x
			host.gsp = host.dec * host.direction.x
		#if total gsp > 0
		elif abs_gsp > 0:
			#push against gsp
			host.gsp += host.dec * host.direction.x
		var brakeLimit = 380
		#if total gsp >= brakeLimit
		if abs_gsp >= brakeLimit:
			#brake
			host.character.rotation_degrees = 0
			if not is_braking:
				brake_sign = gsp_dir
				host.audio_player.play('brake')
			is_braking = true
	else:
		#if not braking and less than cap
		if not is_braking and abs_gsp < host.top:
			#add to speed
			host.gsp += host.acc * host.direction.x
	
	abs_gsp = abs(host.gsp)
	gsp_dir = sign(host.gsp)
	
	var stopBrakeLimit = .1
	#if speed dir != brake dir OR total speed <= stopBrakeLimit
	if gsp_dir != brake_sign or abs_gsp <= stopBrakeLimit:
		#stop braking
		is_braking = false
	
	host.is_pushing = coll_handler.is_pushing_wall()
	#if pushing wall
	if host.is_pushing:
		#set speed to 0.0
		host.gsp = 0.0
	#if coll_handler.is_pushing_wall():
	#	host.gsp = 0.0
	#	host.is_pushing = true
	#else:
	#	host.is_pushing = false
	
	host.is_braking = is_braking
	host.speed = Vector2(host.gsp * cos(ground_angle), host.gsp * -sin(ground_angle))
	
	if host.constant_roll:
		finish("Rolling")
		return
	var okayGround = 30.0
	#if can't fall
	#or 
	##is a justified ground angle
	##and host isn't rotated
	if not host.can_fall or (abs(rad2deg(ground_angle)) <= okayGround && host.rotation != 0):
		coll_handler.snap_to_ground()
	var brakeLimitTime = .5
	if is_braking:
		brake_time += delta
		if brake_time >= brakeLimitTime:
			is_braking = false
			brake_time = 0.0

func state_exit(host, next_state):
	is_braking = false
	host.is_braking = false
	if next_state == "OnAir":
		if host.animation.current_animation == "Rolling":
			host.sprite.offset = Vector2.ONE * -15
			host.sprite.offset.y += 5

func state_animation_process(host, delta:float, animator: CharacterAnimator):
	var gsp_dir = sign(host.gsp)
	var anim_name = idle_anim
	var anim_speed = 1.0
	var abs_gsp = abs(host.gsp);
	var play_once = false
	var coll_handler = host.coll_handler
	var m_handler = host.m_handler
	var ground_angle = coll_handler.ground_angle()
	
	
	
	if abs_gsp > .1 and not is_braking:
		#idle_anim = 'Idle'
		var jogging = 280
		var running = 420
		var faster_run = 960
		
		anim_name = 'Walking'
		if abs_gsp >= jogging and abs_gsp < running:
			anim_name = "Jogging"
		elif abs_gsp >= running and abs_gsp < faster_run:
			anim_name = "Running"
		elif abs_gsp > faster_run:
			anim_name = "SuperPeelOut"
		var host_char = host.character
		#var inv_transform : Transform2D= host.transform.inverse()
		
		#print(host_char.global_rotation)
		if abs(rad2deg(ground_angle)) < 22:
			host_char.rotation = lerp_angle(host_char.rotation, 0, delta * 30)
		else:
			host_char.rotation = lerp_angle(host_char.rotation, -ground_angle, delta * 30)
		anim_speed = max(-(8.0 / 60.0 - (abs_gsp / 120.0)), 1.6)+0.4
		if gsp_dir != 0:
			if abs_gsp > 500:
				host_char.scale.x = gsp_dir
			else:
				host_char.scale.x = host.direction.x if host.direction.x != 0 else host_char.scale.x
	elif is_braking:
		if anim_name != 'BrakeLoop' and anim_name != 'PostBrakReturn':
			anim_name = 'Braking'
		anim_speed = 2.0
		play_once = true;
		match anim_name:
			'BrakeLoop': 
				anim_speed = -((5.0 / 60.0) - (abs(host.gsp) / 120.0));
				play_once = false;
			'PostBrakReturn':
				anim_speed = 1;
		
	else:
		if host.is_pushing:
			#idle_anim = 'Idle'
			anim_name = 'Pushing'
			anim_speed = 1.5;
	
	animator.animate(anim_name, anim_speed, play_once);

func _on_animation_finished(host, anim_name):
	if anim_name == 'Walking':
		is_braking = false
	#elif anim_name == 'Idle':
	#	idle_anim = 'Idle'
	#elif anim_name == 'Idle':
	#	idle_anim = 'Idle'


func on_animation_finished(host, anim_name):
	match anim_name:
		'Walking': is_braking = false;
		#'Idle': idle_anim = 'Idle';
		'Braking':
			var gsp_dir = sign(host.gsp);
			if (host.gsp != 0 ||\
			host.direction.x == -gsp_dir) &&\
			host.direction.x != 0:
				anim_name = 'PostBrakReturn'
			elif host.direction.x == 0 ||\
			host.direction.x == gsp_dir:
				is_braking = false;
				#idle_anim = 'Idle';

func state_input(host, event):
	if host.direction.y != 0:
		var abs_gsp = abs(host.gsp)
		if host.direction.y > 0:
			if abs_gsp > host.min_to_roll:
				finish("Rolling")
			elif host.ground_mode == 0:
				finish("Crouch")
			
	if event.is_action_pressed("ui_jump_i%d" % host.player_index):
		finish(host.jump())
