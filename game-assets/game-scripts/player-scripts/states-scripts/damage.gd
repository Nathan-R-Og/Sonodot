extends State

func state_enter(host, prev_state):
	host.snap_margin = 0

func state_physics_process(host, delta):
	if host.is_on_ceiling():
		if host.speed.y < 0:
			host.speed.y = 0;
	
	if host.is_grounded:
		finish("Idle")
	
	if host.speed.y < 0 and host.speed.y > -240:
		host.speed.x -= (host.speed.x/7.5)/15360
	
	host.speed.y += host.grv

func state_animation_process(host, delta:float, animator: CharacterAnimator):
	var anim_name = "Hurt"
	var anim_speed := 2.0
	host.side = host.direction.x if host.direction.x != 0 else host.side
	animator.animate(anim_name, anim_speed)
