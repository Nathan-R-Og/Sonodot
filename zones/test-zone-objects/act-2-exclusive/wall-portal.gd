extends Area2D

var can_teleport : bool = true setget set_can_teleport 

export(NodePath) var exit_portal_path : NodePath

onready var teleport_sfx : AudioStreamPlayer = $TeleportSFX
onready var exit_portal : Node2D = get_node(exit_portal_path)

func _on_WallPortal_body_entered(body: Node) -> void:
	if !can_teleport and exit_portal == null: return
	if body is PlayerPhysics:
		get_tree().get_current_scene().get_node('HUD').vfx_handler.flash_screen(0.1, 1.0, 3)
		body.position.y = exit_portal.position.y + (position.y - body.position.y)
		body.position.x = exit_portal.position.x
		body.player_camera.position = exit_portal.position + (position - body.player_camera.position)
		teleport_sfx.play()
	
func set_can_teleport(val : bool) -> void:
	can_teleport = val
	set_monitoring(can_teleport)
