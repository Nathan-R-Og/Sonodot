class_name Utils

class Math:
	static func bools_sign(minus:bool, plus:bool) -> int:
		return - int(minus) + int(plus)
	
	static func bool_sign(dir:bool) -> int:
		return - int(!dir) + int(dir)
	
	static func int2bin(n : int, bits: int=1) -> String:
		var to_return := ""
		var num = n
		for i in range(bits, -1, -1):
			var k = num >> i
			to_return += String(int(k & 1))
	
		return to_return

	static func bin2int(b : String) -> int:
		var to_return : int = 0
		var bin = b
		var base = 1
		
		for i in range(b.length() - 1, -1, -1):
			if (bin[i] == "1"):
				to_return += base
			base = base * 2
		
		return to_return
	
	static func count_bits(digit:bool, b:String) -> int:
		var to_return = 0
		var bin = b
		var intd = int(digit)
		for i in b:
			to_return += intd
		
		return to_return
	
	# Convert radians to slices:
	# directions are the possible angles can be returned in radians
	static func rad2slice(val:float, directions:int, round_to:int = 0):
		var findin = directions/2
		var angle_2_dir = val / PI*(findin)
		var final
		if round_to == 0:
			final = round(angle_2_dir)
		elif round_to < 0:
			final = floor(angle_2_dir)
		else:
			final = ceil(angle_2_dir)
		var to_radian = final / findin * PI
		return to_radian

	static func angle2Vec2(angle : float, radius : float= 1) -> Vector2:
		return Vector2(cos(angle), sin(angle))* radius

	static func is_between(val: float, minor:float, major:float) -> bool:
		return val > minor and val < major
	
	static func is_between_ulmost(val: float, minor:float, major:float) -> bool:
		return val >= minor and val <= major
	
	static func invertXY(vec:Vector2) -> Vector2:
		return Vector2(vec.y, vec.x)

class Nodes:
	static func get_node_by_type(from:Node, i:String):
		for c in from.get_children():
			if c.is_class(i):
				return c
		return null

	static func get_parent_by_type(from:Node, i:String, max_search:int):
		var node = from
		var accuracy:int = max_search
		for n in accuracy:
			node = from.get_parent()
			if node.is_class(i):
				return node
		return null

	static func get_nodes_by_type(from:Node, i:String):
		var to_return = []
		for c in from.get_children():
			if c.is_class(i):
				to_return.append(c)
		if to_return.size() <= 0:
			to_return = null
		return to_return
	
	static func new_tween(me : Node) -> Tween:
		var to_return = Tween.new()
		me.add_child(to_return)
		return to_return

	static func create_timer(me: Node, seconds: float) -> Timer:
		var timer : Timer = Timer.new()
		me.add_child(timer)
		timer.start(seconds)
		return timer

class UInput:
	static func is_action(action:String) -> bool:
		return Input.is_action_pressed(action) or Input.is_action_just_released(action)

class Collision:
	static func get_area2D_coll_overlap(collided_area:Area2D, body_rid: RID, body: Node, body_shape_index:int, local_shape_index:int):
		var body_global_transform
		var body_shape_2d
		if !body is TileMap:
			var body_shape_owner_id = body.shape_find_owner(body_shape_index)
			var body_shape_owner = body.shape_owner_get_owner(body_shape_owner_id)
			body_shape_2d = body.shape_owner_get_shape(body_shape_owner_id, 0)
			body_global_transform = body_shape_owner.global_transform
		else:
			var tm : TileMap = body
			body_shape_2d = tm
			body_global_transform = tm.global_transform
		
		var area_shape_owner_id = collided_area.shape_find_owner(local_shape_index)
		var area_shape_owner = collided_area.shape_owner_get_owner(area_shape_owner_id)
		var area_shape_2d = collided_area.shape_owner_get_shape(area_shape_owner_id, 0)
		var area_global_transform = area_shape_owner.global_transform
		
		var collision_points = area_shape_2d.collide_and_get_contacts(area_global_transform,
										body_shape_2d,
										body_global_transform)
		
		for i in collision_points.size():
			collision_points[i] = collision_points[i] - collided_area.position
		
		return collision_points
	static func is_collider_oneway(ray_cast : RayCast2D, collider) -> bool:
		var to_return = false
		if !collider:
			return to_return
		#print(ray_cast.name)
		match collider.get_class():
			'TileMap':
				var tmap : TileMap = collider
				var cell = tmap.get_cellv(tmap.world_to_map(ray_cast.get_collision_point()))
				#print(cell)
				var shape = ray_cast.get_collider_shape()
				if shape && cell >= 0:
					to_return = tmap.get_tileset().tile_get_shape_one_way(cell, shape)
			'StaticBody2D', 'RigidBody2D', "KinematicBody2D":
				var coll : CollisionObject2D = collider
				var collider_shape_id : int = ray_cast.get_collider_shape()
				var collider_shape_owner_id : int = coll.shape_find_owner(collider_shape_id)
				to_return = coll.is_shape_owner_one_way_collision_enabled(collider_shape_owner_id)
		return to_return
	static func get_collider_normal_precise(ray:RayCast2D, ground_mode):
		var collider = ray.get_collider()
		if ground_mode == 0:
			return ray.get_collision_normal()
		while collider:
			if is_collider_oneway(ray, collider):
				ray.add_exception(collider)
				ray.force_raycast_update()
				continue
			return ray.get_collision_normal()
		ray.clear_exceptions()
	
	static func get_shape_size(shape : Shape2D):
		return Vector2(get_width_of_shape(shape), get_height_of_shape(shape))

	static func get_width_of_shape(shape:Shape2D):
		match shape.get_class():
			"RectangleShape2D":
				return (shape as RectangleShape2D).extents.x
			"CircleShape2D":
				return (shape as CircleShape2D).radius
			"CapsuleShape2D":
				var capsule = shape as CapsuleShape2D
				return capsule.radius
	static func get_height_of_shape(shape:Shape2D):
		match shape.get_class():
			"RectangleShape2D":
				return (shape as RectangleShape2D).extents.y
			"CircleShape2D":
				return (shape as CircleShape2D).radius
			"CapsuleShape2D":
				var capsule = shape as CapsuleShape2D
				return capsule.radius + capsule.height

class UArray:
	static func fill_array(size:int, value) -> Array:
		var to_return = []
		for i in size:
			to_return.push_back(value)
		return to_return
	
	static func call_all_array(arr : Array, fn: String, args:Array=[]):
		for i in arr:
			(i as Object).callv(fn, args)
	
	static func pick_random_index(arr:Array):
		if arr.empty():return
		if arr.size() == 1: return arr[0]
		var rng = RandomNumberGenerator.new()
		rng.randomize()
		var index = rng.randi() % arr.size()
		return arr[index]
	
	static func get_x_of_poolvec2(arr : PoolVector2Array) -> Array:
		var to_return : Array = []
		for i in arr:
			to_return.push_back(i.x)
		return to_return
	
	static func get_y_of_poolvec2(arr : PoolVector2Array) -> Array:
		var to_return : Array = []
		for i in arr:
			to_return.push_back(i.y)
		return to_return
