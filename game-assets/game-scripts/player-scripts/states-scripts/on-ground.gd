extends State

var slope : float
var is_braking : bool
var brake_sign : int
var idle_anim = 'Idle'

func state_enter(host, prev_state):
	host.is_pushing = false
	idle_anim = 'Idle'
	host.snap_margin = host.snaps
	host.suspended_jump = false
	

func state_physics_process(host : PlayerPhysics, delta):
	#print("test")
	var gsp_dir = sign(host.gsp)
	var abs_gsp = abs(host.gsp)
	var coll_handler = host.coll_handler
	var m_handler = host.m_handler
	var ground_angle = coll_handler.ground_angle()
	
	if abs_gsp == 0 && host.direction.x == 0:
		finish("Idle")
		return
	
	if !host.is_grounded:
		host.snap_margin = 0
		finish("OnAir")
		return
	
	if !host.is_ray_colliding or coll_handler.fall_from_ground() or host.is_floating:
		host.is_grounded = false
		host.snap_margin = 0
		finish("OnAir")
		return
	
	m_handler.handle_ground_motion()
	ground_angle = coll_handler.ground_angle()
	gsp_dir = sign(host.gsp)
	abs_gsp = abs(host.gsp)
	
	if host.direction.x == -gsp_dir:
		var braking_dec : float = host.dec
		if abs_gsp == 0:
			host.gsp = braking_dec * host.direction.x
		elif abs_gsp > 0:
			host.gsp += braking_dec * host.direction.x
		if abs_gsp >= 380:
			if !is_braking:
				brake_sign = gsp_dir
				host.audio_player.play('brake')
			is_braking = true
	else:
		if !is_braking and abs_gsp < host.top:
				host.gsp += host.acc * host.direction.x
	
	abs_gsp = abs(host.gsp)
	gsp_dir = sign(host.gsp)
	if gsp_dir != brake_sign or abs_gsp <= 0.1:
		is_braking = false
	
	if coll_handler.is_pushing_wall():
		host.gsp = 0.0
		host.is_pushing = true
	else:
		host.is_pushing = false
	
	host.is_braking = is_braking
	
	host.speed.x = host.gsp * cos(ground_angle)
	host.speed.y = host.gsp * -sin(ground_angle)
	
	if host.constant_roll:
		finish("Rolling")
		return
	
	if !host.can_fall or (abs(rad2deg(ground_angle)) <= 30 && host.rotation != 0):
		coll_handler.snap_to_ground()

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
	if abs_gsp > .1 and !is_braking:
		idle_anim = 'Idle'
		var joggin = 280
		var runnin = 420
		var faster_run = 960
		
		anim_name = 'Walking'
		if abs_gsp >= joggin and abs_gsp < runnin:
			anim_name = "Jogging"
		elif abs_gsp >= runnin and abs_gsp < faster_run:
			anim_name = "Running"
		elif abs_gsp > faster_run:
			anim_name = "SuperPeelOut"
		var host_char:Node2D = host.character
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
			idle_anim = 'Idle'
			anim_name = 'Pushing'
			anim_speed = 1.5;
	
	animator.animate(anim_name, anim_speed, play_once);

func _on_animation_finished(host, anim_name):
	if anim_name == 'Walking':
		is_braking = false
	elif anim_name == 'Idle':
		idle_anim = 'Idle'
	elif anim_name == 'Idle':
		idle_anim = 'Idle'


func on_animation_finished(host, anim_name):
	match anim_name:
		'Walking': is_braking = false;
		'Idle': idle_anim = 'Idle';
		'Braking':
			var gsp_dir = sign(host.gsp);
			if (host.gsp != 0 ||\
			host.direction.x == -gsp_dir) &&\
			host.direction.x != 0:
				anim_name = 'PostBrakReturn'
			elif host.direction.x == 0 ||\
			host.direction.x == gsp_dir:
				is_braking = false;
				idle_anim = 'Idle';

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
