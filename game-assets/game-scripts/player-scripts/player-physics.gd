extends KinematicBody2D
class_name PlayerPhysics
# imports
onready var m_handler = preload("res://game-assets/game-scripts/player-scripts/motion-handler.gd").new(self)
onready var coll_handler = preload("res://game-assets/game-scripts/player-scripts/collision-handler.gd").new(self)

#enum Side{
#	LEFT=-1, RIGHT=1
#}


signal damaged
signal rings_update(value)
signal character_changed(previous_character, current_character)
var rings = 100 setget set_rings
var score = 0
var player_index: int
var respawn_point : Vector2
var main_player = false
var robot = false

export var selected_character_index = 0 setget set_selected_character

var acc
var dec
var roll_dec
var frc
var slp
var slp_roll_up
var slp_roll_down
var top
var top_roll
var jmp
var fall
var air
var grv
var spin_dash

var my_spawn_point : PlayerSpawner
onready var selected_character_node : Character
onready var fsm = $StateMachine
onready var shield_container := $ShieldContainer
var char_state_manager
onready var player_camera = $CameraSpace/PlayerCamera
onready var player_vfx = $VFX
onready var GLOBAL = get_tree().get_root().get_node("./AutoloadMain")

onready var left_ground:RayCast2D = $GroundSensors/LeftGroundSensor
onready var right_ground:RayCast2D = $GroundSensors/RightGroundSensor
onready var middle_ground:RayCast2D = $GroundSensors/MiddleGroundSensor
onready var ground_sensors_container:Node2D = $GroundSensors
onready var main_collider:CollisionShape2D = $MainCollider
onready var left_wall:RayCast2D = $LeftWallSensor
onready var right_wall:RayCast2D = $RightWallSensor
onready var left_wall_bottom:RayCast2D = $LeftWallSensorBottom
onready var right_wall_bottom:RayCast2D = $RightWallSensorBottom
onready var attack_area : Area2D = $AttackBox
onready var attack_shape : CollisionShape2D = attack_area.get_node("hitbox")

onready var hitbox_area = $HitBox
onready var hitbox_shape = hitbox_area.get_node("hitbox")

onready var characters_path = AutoloadCharacters.characters
onready var character = $Character
onready var sprite
var char_default_collision
var char_roll_collision
onready var animation : CharacterAnimator
onready var audio_player:SoundMachine = $AudioPlayer
onready var main_scene = get_tree().current_scene
var snaps : float = 15
var snap_margin = snaps

var ring_scene = preload("res://general-objects/ring-physical-object.tscn")

var direction : Vector2 = Vector2.ZERO
var gsp : float
var speed : Vector2
var ground_mode : int
var control_locked = false
#var control_locked : bool = false setget , is_control_locked
const control_unlock_time_normal = .5
onready var control_unlock_timer : Timer = $ControlUnlockTimer

var can_fall : bool
var is_ray_colliding : bool
var is_grounded : bool
var ground_point : Vector2
var ground_normal : Vector2
var has_jumped : bool
var is_floating : bool
var is_braking : bool
var was_damaged : bool
var is_wall_left : bool
var is_wall_right : bool
var is_pushing : bool
var spring_loaded : bool
var spring_loaded_v : bool
var invulnerable : bool = false
var constant_roll : bool
var boost_constant_roll : bool
var up_direction : Vector2 = Vector2.UP
var prev_position : Vector2
var ground_ray : RayCast2D
var can_break_wall : bool = false setget _set_can_break_wall
var suspended_jump : bool = false
var suspended_can_right : bool = true
var suspended_can_left : bool = true
var throwed : bool = false
var input_dict : Dictionary
var speed_shoes : bool = false setget set_speed_shoes
var underwater : bool = false setget set_underwater
var roll_anim: bool = false
var min_to_roll := 100.0
var side : int setget set_side, get_side
var is_attacking : bool = false setget set_is_attacking
var previous_rotation : float = 0.0
# change to false when changes state
var play_specific_anim : bool = false setget set_play_specific_anim

#literally why
#func _enter_tree():
#	set_physics_process(false)
#	set_process(false)

func _ready():
	if Engine.editor_hint: return
	#set_physics_process(false)
	#set_process(false)
	#hitbox_area.set_owner(self)
	#attack_area.set_owner(self)
	
	#so that they can animate independently
	character.set_as_toplevel(true)
	shield_container.set_as_toplevel(true)
	
	
	fsm._on_host_ready(self)
	shield_container._on_host_ready(self)
	
	#set character
	set_selected_character(selected_character_index)
	
	#set_collision_mask(get_collision_mask())
	#yield(selected_character_node, "ready")
	#selected_character_node.on_player_load_me()
	
	#if player camera exists, set to this
	if player_camera:
		player_camera.camera_ready(self)
	#set_process(true)
	#set_physics_process(true)

func get_rays():
	return [left_ground, middle_ground, right_ground, left_wall, left_wall_bottom, right_wall, right_wall_bottom]
	

func get_ray(val):
	return get_rays()[val]

func set_ground_rays(val):
	for i in [middle_ground, left_ground, right_ground]:
		i.set_deferred("enabled", val)

# override
func set_collision_mask(val : int):
	.set_collision_mask(val)
	for i in get_rays():
		i.set_collision_mask(val)
func set_collision_mask_bit(val : int, switch : bool):
	.set_collision_mask_bit(val, switch)
	for i in get_rays():
		i.set_collision_mask_bit(val, switch)

func _set_can_break_wall(val : bool):
	can_break_wall = val
	set_collision_mask_bit(5, can_break_wall)
	set_collision_layer_bit(5, can_break_wall)
	

func set_speed_shoes(val : bool):
	speed_shoes = val
	for i in ['top', 'acc', 'dec', 'frc']:
		set(i, selected_character_node.character_values.get(i) * (1 if !speed_shoes else 1.7))
	if underwater:
		for i in ['top', 'acc', 'dec', 'frc', 'air']:
			set(i, get(i) / (1 if !underwater else 2))
		if underwater:
			jmp = selected_character_node.jmp/1.5
			grv = selected_character_node.grv/4
		else:
			jmp = selected_character_node.jmp
			grv = selected_character_node.grv
	player_vfx.get_node('Trail').enabled = speed_shoes

func set_underwater(val:bool):
	underwater = val
	for i in ['top', 'acc', 'dec', 'frc', 'air']:
		set(i, selected_character_node.character_values.get(i) / (1 if !underwater else 2))
	if underwater:
		jmp = selected_character_node.jmp/1.5
		grv = selected_character_node.grv/4
	else:
		jmp = selected_character_node.jmp
		grv = selected_character_node.grv
	if speed_shoes:
		for i in ['top', 'acc', 'dec', 'frc', 'air']:
			set(i, get(i) * (1 if !speed_shoes else 1.7))

func _physics_process(delta: float):
	fsm._fsm_physics_process(delta)
	coll_handler.step_collision(delta)
	speed = move_and_slide_preset()
	if is_grounded:
		ground_sensors_container.global_rotation = -coll_handler.ground_angle()
	else:
		ground_sensors_container.global_rotation = 0
	if player_camera:
		position.x = max(player_camera.camera.limit_left+9, position.x)
		position.x = min(player_camera.camera.limit_right-9, position.x)
	else:
		position.x = max(9, position.x)
	is_grounded = is_on_floor()
	ground_ray = coll_handler.get_ground_ray()
	is_ray_colliding = ground_ray != null
	if ground_ray and is_ray_colliding:
		if Utils.Collision.is_collider_oneway(ground_ray, ground_ray.get_collider()) and ground_mode != 0:
			ground_normal = ground_ray.get_collision_normal()
			ground_mode = 0
			return
		ground_normal = Utils.Collision.get_collider_normal_precise(ground_ray, ground_mode)
		ground_mode = int(round(coll_handler.ground_angle() / (PI * 0.5))) % 4
		ground_mode = 2 if ground_mode == -2 else ground_mode
	else:
		ground_mode = 0
		ground_normal = Vector2(0, -1)
		is_grounded = false
	
	is_wall_left = coll_handler.is_colliding_on_wall(left_wall) or coll_handler.is_colliding_on_wall(left_wall_bottom)
	is_wall_right = coll_handler.is_colliding_on_wall(right_wall) or coll_handler.is_colliding_on_wall(right_wall_bottom)
	if player_camera:
		is_wall_left = is_wall_left or global_position.x- Utils.Collision.get_width_of_shape(main_collider.shape) - player_camera.camera.limit_left <= 0
		is_wall_right = is_wall_right or global_position.x+9 - player_camera.camera.limit_right >= 0

func _process(delta : float):
	fsm._fsm_process(delta)
	character.global_position = global_position
	character.z_index = z_index
	character.visible = visible
	shield_container.global_position = global_position
	
	
	if !is_attacking:
		shield_container.scale.x = side
	else:
		if speed.x != 0:
			shield_container.scale.x = sign(speed.x)
		else:
			shield_container.scale.x = side
	
	roll_anim = animation.current_animation == 'Rolling' or selected_character_node.is_rolling

func play_specific_anim_until(animation_name : String, custom_speed : float = 1.0, can_loop : bool = true, node:Object = fsm, signal_name = "state_changed"):
	play_specific_anim = true
	animation.animate(animation_name, custom_speed, can_loop)
	if node != null and signal_name != null:
		_wait_for_specific_anim_ends(node, signal_name)

func _wait_for_specific_anim_ends(node, signal_name):
	yield(node, signal_name)
	_ended_specific_anim(node, signal_name)

func _ended_specific_anim(node : Object, signal_name):
	play_specific_anim = false
	if !is_instance_valid(node): return
	if node.is_connected(signal_name, self, 'ended_specific_anim'):
		node.disconnect(signal_name, self, 'ended_specific_anim')

func lock_control(time:float = control_unlock_time_normal):
	control_locked = true
	control_unlock_timer.start(time)

func unlock_control():
	control_locked = false
	control_unlock_timer.stop()

#func is_control_locked() -> bool:
#	return control_locked

func damage(side:Vector2 = Vector2.ZERO, sound_to_play:String = "hurt"):
	if invulnerable:
		return
	emit_signal("damaged")
	var time_invulnerable = 4.0
	var timer = get_tree().create_timer(time_invulnerable)
	invulnerable_until(timer, "timeout")
	blink(time_invulnerable)
	snap_margin = 0
	lock_control()
	was_damaged = true
	speed.x = side.x * 220
	speed.y = side.y * 200
	set_side(-sign(speed.x) if speed.x != 0 else side)
	is_grounded = false
	fsm.change_state("Damage")
	speed = move_and_slide_preset()
	if shield_container.activated:
		audio_player.play(sound_to_play)
		shield_container.detach_shield()
		return
	if rings > 0:
		drop_rings()
		audio_player.play("ring_loss")
		var ground_angle = coll_handler.ground_angle()
	else:
		audio_player.play(sound_to_play)

func invulnerable_until(obj, until:String):
	invulnerable = true
	obj.connect(until, self, "make_vulnerable")

func blink(sec : float):
	var t: SceneTreeTimer = get_tree().create_timer(sec)
	while t != null and t.time_left > 0:
		sprite.modulate.a = 0.25
		yield(get_tree().create_timer(0.075), "timeout")
		sprite.modulate.a = 1
		yield(get_tree().create_timer(0.075), "timeout")
	sprite.modulate.a  = 1

func drop_rings():
	var n = false;
	var drop_max:int = 32;
	var drop_real:int = min(drop_max, rings); 
	var angle = -deg2rad(101.25)
	var drop_speed = 300
	
	for i in drop_real:
		var instance_ring = ring_scene.instance()
		call_deferred("add_child", instance_ring)
		instance_ring.set_as_toplevel(true)
		instance_ring.position = position;
		instance_ring.position.y -= 10
		instance_ring.linear_velocity.x = cos(angle) * drop_speed 
		instance_ring.linear_velocity.y = sin(angle) * drop_speed
		if n:
			instance_ring.linear_velocity.x *= -1
			angle += deg2rad(22.5);
		n = !n;
		if i == drop_real * 0.5:
			drop_speed *= 0.5
			angle = deg2rad(101.25)

func make_vulnerable():
	was_damaged = false
	invulnerable = false
	modulate.a = 1.0

func set_selected_character(val):
	# Check for character
	if !character: return
	
	selected_character_index = clamp(val, 0, characters_path.size())
	var previous_character
	if selected_character_index != val:
		#bug
		if character.get_children().size() != 0:
			previous_character = character.get_child(0)
		var current_character_scene: PackedScene = load(characters_path[selected_character_index].path)
		selected_character_node = current_character_scene.instance()
	else:
		
		selected_character_node = character.get_child(0)
	
	selected_character_node.msm.character_ready(selected_character_node)
	
	char_state_manager = selected_character_node.msm
	sprite = selected_character_node.get_node("Sprite")
	var coll_container = selected_character_node.get_node("CollisionContainer")
	char_default_collision = coll_container.get_node("DefaultBox")
	char_roll_collision = coll_container.get_node("RollBox")
	animation = sprite.get_node("CharAnimation")
	animation.connect("animation_finished", fsm, "_on_CharAnimation_animation_finished")
	var properties = [
		"acc", "dec", "roll_dec", "frc", "slp", "slp_roll_up",
		"slp_roll_down", "top", "top_roll", "jmp", "fall", "air",
		"grv", "spin_dash"
	]
	for i in properties:
		if !get(i):
			set(i, selected_character_node.character_values.get(i))
	
	if selected_character_index != val:
		emit_signal("character_changed", previous_character, selected_character_node)

func _on_ControlUnlockTimer_timeout():
	control_unlock_timer.set_wait_time(control_unlock_time_normal)
	unlock_control()

func move_and_slide_preset(val = null):
	var top_collide = Vector2(sin(rotation), -cos(rotation))
	#var fways:Vector2 = Utils.angle2Vec2(Utils.rad2dir(top_collide.angle_to(Vector2.LEFT), 4))
	#print(bottom_snap)
	return move_and_slide_with_snap(
		speed if !val else val,
		-top_collide * snap_margin,
		top_collide,
		true,
		4,
		deg2rad(76),
		true
	)


func jump():
	snap_margin = 0
	var ground_angle = coll_handler.ground_angle()
	speed += Vector2(-jmp * sin(ground_angle), -jmp * cos(ground_angle))
	speed = move_and_slide_preset()
	is_grounded = false
	spring_loaded = false
	is_floating = false
	has_jumped = true
	audio_player.play('jump')
	return 'OnAir'

func set_side(val : int):
	side = val
	character.scale.x = side

func get_side() -> int:
	if character and character.scale.x != 0:
		return int(sign(character.scale.x))
	return 1

func activate():
	main_player = true
	player_camera.camera.current = true

func deactivate():
	main_player = false
	player_camera.camera.current = false

func set_play_specific_anim(val : bool):
	play_specific_anim = val

func erase_state():
	speed = Vector2.ZERO
	gsp = 0
	direction = Vector2.ZERO
	character.rotation = 0
	constant_roll = false
	sprite.offset = Vector2(-15, -15)
	spring_loaded = false
	spring_loaded_v = false
	has_jumped = false
	selected_character_node.erase_state()

func set_is_attacking(val : bool):
	is_attacking = val
	attack_area.monitoring = is_attacking

func set_rings(val : int):
	rings = val
	emit_signal("rings_update", val)

func do_nothing_until(node: Node, signal_name: String):
	do_nothing()
	node.connect(signal_name, self, "do_all")

func do_nothing():
	set_physics_process(false)
	set_process(false)
	set_process_unhandled_input(false)

func do_all():
	set_physics_process(true)
	set_process(true)
	set_process_unhandled_input(true)

func _unhandled_input(event: InputEvent):
	var action_chk = funcref(Utils.UInput, "is_action")
	if !control_locked:
		var ui_left = 'ui_left_i%d' % player_index
		var ui_right = 'ui_right_i%d' % player_index
		if action_chk.call_func(ui_right) or action_chk.call_func(ui_left):
			direction.x = Input.get_axis(ui_left, ui_right)
	else:
		direction.x = 0.0
	
	var ui_up = 'ui_up_i%d' % player_index
	var ui_down = 'ui_down_i%d' % player_index
	if action_chk.call_func(ui_up) or action_chk.call_func(ui_down):
		direction.y = Input.get_axis(ui_up, ui_down)
	
	fsm._fsm_input(event)

func get_class():
	return "PlayerPhysics"
func is_class(val):
	return val == get_class() or .is_class(val)
