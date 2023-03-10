extends State

var has_jumped : bool
var has_rolled : bool
var spring_loaded : bool

var spring_loaded_v : bool
var roll_jump : bool
var is_floating
var override_anim : String
#var post_damage:bool
var was_throwed : bool = false
var spring_anim = false


func state_enter(host, prev_state):
	host.snap_margin = 0
	host.ground_sensors_container.rotation = 0
	if host.spring_loaded or host.roll_anim:
		host.character.rotation = 0
	has_jumped = host.has_jumped
	spring_loaded = host.spring_loaded
	is_floating = host.is_floating
	spring_loaded_v = host.spring_loaded_v
	
	host.has_jumped = false
	host.spring_loaded = false
	host.is_floating = false
	host.spring_loaded_v = false
	roll_jump = has_jumped and has_rolled
	
	host.rotation = 0

func state_physics_process(host: PlayerPhysics, delta):
	#add air control
	#sorry, no jump-locking for me!
	host.speed.x += host.acc * host.direction.x / 2.0
	#print(host.roll_anim)
	if host.roll_anim:
		host.sprite.offset = Vector2(-15, -10)
	host.character.rotation = lerp_angle(host.character.rotation, 0, 0.25)
	host.m_handler.handle_air_motion()
	
	#set to walking after peaked spring height
	if host.spring_loaded_v and not spring_anim:
		spring_anim = true
	elif host.speed.y >= 0 and host.animation.current_animation == 'SpringJump' and spring_anim:
		spring_anim = false
		host.animation.animate('Walking', 3, true)
	
	if has_jumped:
		var ui_jump = "ui_jump_i%d" % host.player_index
		if Input.is_action_just_released(ui_jump): # has jumped
			var jmp_release = -240.0
			if host.underwater:
				jmp_release *= 0.5
			if host.speed.y < jmp_release: # set min jump height
				host.speed.y = jmp_release
	
	if host.is_grounded:
		finish('OnGround')
		return
	if host.direction.x != 0:
		host.side = host.direction.x

func state_exit(host, next_state):
	is_floating = false
	host.is_floating = false
	was_throwed = false
	host.throwed = false
	spring_loaded = false
	spring_loaded_v = false
	host.spring_loaded = false
	host.spring_loaded_v = false
	if host.is_grounded:
		if host.was_damaged:
			host.control_locked = false
			host.gsp = 0
			host.was_damaged = false
		else:
			host.coll_handler.ground_reacquisition()
	set_state_animation_processing(true)

func state_animation_process(host, delta:float, animator: CharacterAnimator):
	var anim_name = animator.current_animation
	var anim_speed = animator.get_playing_speed()
	if spring_loaded_v:
		has_jumped = false
	if anim_name == 'Walking':
		anim_speed = 3
	if anim_name == 'Braking':
		anim_name = 'Walking';
		anim_speed = 3
	if has_jumped or has_rolled:
		anim_name = 'Rolling';
		host.character.rotation = 0
		anim_speed = max(-((5.0 / 60.0) - (abs(host.gsp) / 120.0)), 1.0);
	
	animator.animate(anim_name, anim_speed, true)
	
	set_state_animation_processing(true)


func on_animation_finished(host, anim_name) -> void:
	match anim_name:
		'Rotating':
			if was_throwed && !is_floating:
				was_throwed = false
				host.animation.current_animation = 'Walking'
