extends State

var animation_frame = 0.0
var crouched = false
var slope : float

func state_enter(host : PlayerPhysics, prev_state : String):
	host.speed = Vector2.ZERO
	host.gsp = 0
	animation_frame = 0.0

func state_physics_process(host : PlayerPhysics, delta: float):
	var ground_angle = host.coll_handler.ground_angle()
	slope = -host.slp_roll_up
	host.gsp += slope * sin(ground_angle)
	host.gsp -= min(abs(host.gsp), host.frc) * sign(host.gsp)
	if !host.is_grounded:
		finish("OnAir")
	if host.gsp != 0:
		finish("Rolling")

func state_animation_process(host: PlayerPhysics, delta:float, animator: CharacterAnimator):
	var play_speed := Utils.Math.bool_sign(host.direction.y > 0) * 4.0 
	var loop = true
	if animator.current_animation_position == animator.current_animation_length || animator.current_animation_position == 0:
		loop = false
	crouched = animator.current_animation_position != 0 || host.direction.y > 0
	if !crouched:
		play_speed = 0.0
		animation_frame = 0.0
		return
	if play_speed >= 0:
		animator.animate('Down', play_speed, true)
	else:
		animator.animate_from_end('Down', play_speed, true)

func state_animation_finished(host, anim_name):
	match anim_name:
		'Down':
			if host.animation.current_animation_position == 0:
				if host.direction.x == 0:
					finish('Idle')
				else:
					finish('OnGround')

func _exit_tree() -> void:
	animation_frame = 0.0

func state_input(host, event):
	if crouched:
		if Input.is_action_just_pressed('ui_jump_i%d' % host.player_index) && host.spin_dash:
			finish("SpinDash")
			return
