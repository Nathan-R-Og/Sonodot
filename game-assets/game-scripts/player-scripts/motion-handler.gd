extends Object

# PlayerPhysics
var host
#set parent
func _init(_host):
	host = _host


func handle_ground_motion():
	host.gsp -= host.slp * sin(host.coll_handler.ground_angle())
	if host.direction.x == 0:
		host.is_braking = false
		host.gsp -= min(abs(host.gsp), host.frc) * sign(host.gsp)
		if abs(host.gsp) < 0.1:
			host.fsm.change_state("Idle")

func handle_rolling_motion():
	var ground_angle = host.coll_handler.ground_angle()
	var slope = 0.0
	if sign(host.gsp) == sign(sin(ground_angle)):
		slope = -host.slp_roll_up
	else:
		slope = -host.slp_roll_down
	host.gsp += slope * sin(ground_angle)
	if host.direction.x != 0 and host.direction.x == -sign(host.gsp):
		if abs(host.gsp) > 0 :
			var braking_dec : float = host.roll_dec
			host.gsp += braking_dec * host.direction.x
	else:
		host.gsp -= min(abs(host.gsp), host.frc / 2.0) * sign(host.gsp)
	if host.constant_roll:
		if host.boost_constant_roll:
			if abs(host.gsp) < 300:
				host.gsp += (host.top_roll - abs(host.gsp)) * host.side * host.acc
				host.gsp = clamp(host.gsp, -300, 300)
		host.lock_control()

func handle_air_motion():
	if host.direction.x != 0:
		if abs(host.speed.x) < host.top:
			host.speed.x += host.air * host.direction.x
	if host.speed.y < 0 and host.speed.y > -240:
		host.speed.x -= (host.speed.x/7.5)/15360.0
	host.speed.y += host.grv
