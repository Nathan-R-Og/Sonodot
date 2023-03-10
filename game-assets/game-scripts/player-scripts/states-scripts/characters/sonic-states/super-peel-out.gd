extends StateChar

export(float) var dash_speed = 720
export(float) var charge_time = 1

var charge_timer : float
var animation_speed : float

func state_enter(host: PlayerPhysics, prev_state, main_state = null):
	charge_timer = charge_time
	animation_speed = 1.0
	host.audio_player.play('peel_out_charge')

func state_physics_process(host: PlayerPhysics, delta, main_state = null):
	charge_timer -= delta
	animation_speed += (720.0 / pow(charge_time, 2.0)) * delta
	animation_speed = min(animation_speed, 720.0)
	
	if Input.is_action_just_released("ui_up_i%d" % host.player_index):
		finish("OnGround")

func state_exit(host: PlayerPhysics, next_stage:String, main_state = null):
	if charge_timer <= 0:
		host.gsp = dash_speed * host.character.scale.x * host.fsm.get_physics_process_delta_time() * 60
		host.audio_player.play('peel_out_release')
		host.player_camera.delay(0.25)
	else:
		host.audio_player.stop('peel_out_charge')

func state_animation_process(host: PlayerPhysics, delta:float, animator:CharacterAnimator, state = null):
	var anim_speed = max(-(8.0 / 60.0 - (animation_speed / 120.0)), 1.0)
	var anim_name = 'Walking'
	if animation_speed >= 270:
		anim_name = 'Running'
	#if animation_speed >= 540:
	#	anim_name = 'Running'
	if animation_speed >= 720:
		anim_name = 'SuperPeelOut'
	
	animator.animate(anim_name, anim_speed, false)
