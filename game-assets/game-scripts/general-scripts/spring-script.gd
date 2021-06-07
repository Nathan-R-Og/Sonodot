tool
extends StaticNode2D
signal pushed_by_spring

enum Springs{YELLOW, RED}

export var push_force = 500;
var sprite : AnimatedSprite;
onready var jump_collide = $JumpArea/JumpCollide
onready var animplayer:AnimationPlayer = $AnimationPlayer
export(Springs) var spring_presset:int setget _set_spring_presset
const _pressets = {
	Springs.YELLOW: [500, "Yellow"],
	Springs.RED: [700, "Red"]
}

func _ready():
	set_rotation_degrees(rotation_degrees)

func _set_spring_presset(val:int) -> void:
	spring_presset = val
	var vals = _pressets[spring_presset]
	push_force = vals[0]
	for i in get_children():
		if i is Node2D && i != self:
			for j in i.get_children():
				if j is AnimatedSprite:
					j.visible = false
					if j.name == vals[1]:
						sprite = j
						sprite.set_visible(true)
		if i is AnimationPlayer:
			if sprite:
				i.root_node = sprite.get_path()
	if sprite:
		sprite.set_visible(true)
	update()

func _on_JumpArea_body_entered(body):
	if body is PlayerPhysics:
		var player:PlayerPhysics = body;
		var abs_p_angle = abs(player.rotation_degrees)
		var abs_rot = abs(rotation_degrees)
		animplayer.play("Push", -1, 2);
		player.audio_player.play('spring');
		#var ground_angle = player.ground_angle();
		var sp : float = -push_force * cos(rotation);
		#print(abs_rot)
		if abs_rot == 0 or abs_rot == 180:
			if player.is_grounded:
				player.set_rays(false)
				player.is_grounded = false
				player.fsm.change_state("OnAir")
			player.snap_margin = 0
			player.speed.y = sp
			if abs_p_angle > 22.5 && abs_p_angle < 155: 
				pass
				#player.position.y += player.speed.y * get_physics_process_delta_time()
			player.rotation = 0
		elif abs_rot == 90 or abs_rot == 270:
			if player.is_grounded:
				match player.ground_mode:
					0:
						player.gsp = push_force*1.5 * sin(rotation);
					_:
						if abs(player.ground_mode) == 1:
							player.speed.x = push_force * -player.ground_mode;
							player.position.x += player.speed.x * get_physics_process_delta_time()
							player.speed.y = 0;
						player.is_grounded = false;
						player.fsm.change_state("OnAir")
			else:
				player.speed.x = push_force * 1.5 * sin(rotation);
		player.spring_loaded = true
		player.speed = player.move_and_slide(player.speed)

func _on_AnimationPlayer_animation_finished(anim_name):
	animplayer.play("Stop");


func _on_ActivateArea_body_entered(player):
	jump_collide.set_deferred("disabled", false);


func _on_ActivateArea_body_exited(player):
	jump_collide.set_deferred("disabled", true)
