extends Area2D
tool

var dive : PackedScene = preload('res://general-objects/water-dive-object.tscn')
onready var coll_shape:CollisionShape2D = Utils.get_node_by_type(self, 'CollisionShape2D')
export var size : Vector2
var overlaps:Dictionary
export var color : Color = Color(0, 0.5, 0.7, 0.5) setget _update_color
func _ready() -> void:
	var edi_coll_shape : CollisionShape2D = Utils.get_node_by_type(self, 'CollisionShape2D')
	size = edi_coll_shape.shape.extents

func get_coll_overlap(body_id: int, body: Node, body_shape:int, local_shape:int):
	var body_shape_owner_id = body.shape_find_owner(body_shape)
	var body_shape_owner = body.shape_owner_get_owner(body_shape_owner_id)
	var body_shape_2d = body.shape_owner_get_shape(body_shape_owner_id, 0)
	var body_global_transform = body_shape_owner.global_transform
	
	var area_shape_owner_id = shape_find_owner(local_shape)
	var area_shape_owner = shape_owner_get_owner(area_shape_owner_id)
	var area_shape_2d = shape_owner_get_shape(area_shape_owner_id, 0)
	var area_global_transform = area_shape_owner.global_transform
	
	var collision_points = area_shape_2d.collide_and_get_contacts(area_global_transform,
									body_shape_2d,
									body_global_transform)
	for i in collision_points.size():
		collision_points[i] = collision_points[i] - position
	
	return collision_points

func spawn_dive(p : PlayerPhysics, overlap:Array, local_shape:int):
	var dive_obj : AnimatedSprite = dive.instance()
	var overlapp = overlap[0]
	var shape_owner = shape_owner_get_owner(local_shape)
	var shape_owner_id = shape_find_owner(local_shape)
	var shape_collided = shape_owner_get_shape(shape_owner_id, local_shape)
	print(overlapp, shape_owner.position.y - shape_collided.extents.y)
	var minx : float
	var maxx : float
	if shape_collided is RectangleShape2D:
		var sh : RectangleShape2D = shape_collided
		if overlapp.y > shape_owner.position.y - sh.extents.y:
			return
		maxx = shape_owner.position.x + sh.extents.x
		minx = shape_owner.position.x - sh.extents.x
	elif shape_collided is ConvexPolygonShape2D:
		var sh : ConvexPolygonShape2D = shape_collided
		minx = Utils.get_min_vector2pool(sh.get_points(), 'x')
		maxx = Utils.get_max_vector2pool(sh.get_points(), 'x')
		pass
	dive_obj.position = overlapp+position
	dive_obj.position.x = position.x - min(maxx-44, max(minx+44, position.x-p.position.x))
	print(minx, maxx)
	dive_obj.position.y -= 32
	dive_obj.z_index = 100
	dive_obj.set_as_toplevel(true)
	add_child(dive_obj)
	return dive_obj

func _draw() -> void:
	if !size:
		size = Utils.get_node_by_type(self, 'CollisionShape2D').shape.extents
	if !coll_shape:
		coll_shape = Utils.get_node_by_type(self, 'CollisionShape2D')
	draw_rect(Rect2(coll_shape.position-size, size*2), color)
	#print(size)

func _update_color(val : Color) -> void:
	color = val
	update()


func _on_WaterLevel_area_shape_entered(area_id: int, area: Area2D, area_shape: int, local_shape: int) -> void:
	if Engine.editor_hint || !area:
		return
	if area.name == 'WaterSensor':
		var p : PlayerPhysics = area.get_parent()
		p.underwater = true
		overlaps[p] = get_coll_overlap(area_id, area, area_shape, local_shape)
		if overlaps.has(p):
			spawn_dive(p, overlaps[p], local_shape)


func _on_WaterLevel_area_shape_exited(area_id: int, area: Area2D, area_shape: int, local_shape: int) -> void:
	if Engine.editor_hint || !area:
		return
	if area.name == 'WaterSensor':
		var p : PlayerPhysics = area.get_parent()
		p.underwater = false
		if overlaps.has(p):
			spawn_dive(p, overlaps[p], local_shape)
			overlaps.erase(p)
