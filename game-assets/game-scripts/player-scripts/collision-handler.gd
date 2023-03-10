extends Object

#set parent
var host
func _init(_host):
	host = _host

func step_collision(delta):
	#setup collision
	if !host.roll_anim:
		host.main_collider.shape = host.char_default_collision.shape
	else:
		host.main_collider.shape = host.char_roll_collision.shape
	if !host.roll_anim:
		host.main_collider.position = host.char_default_collision.position
	else:
		host.main_collider.position = host.char_roll_collision.position
	host.attack_shape.shape = host.selected_character_node.current_attack_shape.shape
	host.attack_shape.position = host.selected_character_node.current_attack_shape.position
	host.hitbox_shape.shape = host.main_collider.shape
	host.hitbox_shape.position = host.main_collider.position
	
	
	#check_if_can_break

	#var cannot_break_bottom = host.speed.y > 0 or !host.roll_anim
	host.set_collision_mask_bit(7, host.speed.y >= 0)
	var cannot_break_top = host.speed.y > 0 and host.roll_anim
	host.set_collision_mask_bit(8, !cannot_break_top)
	host._set_can_break_wall(!(abs(host.gsp) > 270 and host.fsm.is_current_state("Rolling") and host.is_grounded))
	
	# invert roll_anim
	var inv_roll_anim = !host.roll_anim
	host.set_collision_mask_bit(6, inv_roll_anim)

#get wall collision
func is_colliding_on_wall(wall_sensor : RayCast2D) -> bool:
	var collider = wall_sensor.get_collider()
	if collider:
		var one_way = Utils.Collision.is_collider_oneway(wall_sensor, collider)
		var coll_angle = abs(floor(wall_sensor.get_collision_normal().angle()))
		var grounded_wall = is_equal_approx(coll_angle, PI) or is_equal_approx(coll_angle, 0) 
		grounded_wall = grounded_wall and host.is_grounded and host.ground_mode != 0
		var air_wall = abs(host.rotation) > deg2rad(15) and !host.is_grounded
		if one_way or grounded_wall or air_wall:
			return false
		return true
	return false
#get if pushing wall
func is_pushing_wall() -> bool:
	return (host.is_wall_right and host.gsp > 0) or (host.is_wall_left and host.gsp < 0)

func get_ground_ray() -> RayCast2D:
	host.can_fall = true
	if not host.left_ground.is_colliding() and host.right_ground.is_colliding():
		return host.right_ground
	elif host.left_ground.is_colliding() and not host.right_ground.is_colliding():
		return host.left_ground
	elif not (host.left_ground.is_colliding() or host.right_ground.is_colliding()):
		return null
	host.can_fall = false
	var l_relative_point = host.left_ground.get_collision_point() - host.position
	var r_relative_point = host.right_ground.get_collision_point() - host.position
	var left_point = sin(host.rotation) * l_relative_point.x + cos(host.rotation) + l_relative_point.y
	var right_point = sin(host.rotation) * r_relative_point.x + cos(host.rotation) + r_relative_point.y
	if left_point <= right_point:
		return host.left_ground
	return host.right_ground

#get ground angle
func ground_angle() -> float:
	return host.ground_normal.angle_to(Vector2(0, -1))

#snaps (collision) to rotation of slope
func snap_to_ground() -> void:
	#var g_angle_final = ground_ang
	#host.previous_rotation = host.rotation
	
	#the higher, the more available rotations
	var rotationFiness = 16
	host.rotation = -Utils.Math.rad2slice(ground_angle(), rotationFiness)
	host.speed += -host.ground_normal * 150

func ground_reacquisition() -> void:
	var ground_angle = ground_angle();
	host.gsp = (cos(ground_angle) * host.speed.x) + (-sin(ground_angle) * host.speed.y)

func is_on_ground() -> bool:
	var ground_ray = get_ground_ray()
	if ground_ray != null:
		var point = ground_ray.get_collision_point()
		var normal = ground_ray.get_collision_normal()
		if abs(rad2deg(normal.angle_to(Vector2(0, -1)))) < 90:
			var player_pos = host.global_position.y + 10 + Utils.Collision.get_height_of_shape(host.main_collider.shape)
			return player_pos > point.y
	return false

func fall_from_ground() -> bool:
	if should_slip():
		var deg_angle = rad2deg(ground_angle())
		var angle = abs(deg_angle)
		var r_angle = round(angle)
		host.lock_control()
		if r_angle >= 90 and r_angle <= 180:
			host.ground_mode = 0
			return true
		else:
			host.gsp += 2.5 * Utils.Math.bool_sign((deg_angle + 180) < 180)
	return false

func should_slip() -> bool:
	return abs(host.gsp) < host.fall and host.ground_mode != 0

