extends CharacterBody2D

@export var max_velocity = 100
@export var strength = 100

@onready var right_hand = $Marker2D
@onready var right_hand_item = null
@export var snap_dist = 100
var snap_dist_squared = snap_dist * snap_dist

var view_objects = [] # stores the objects
var snapable_objects = [] # stores the snapping points

func _physics_process(_delta: float) -> void:
	velocity = Vector2(0,0)
	
	# Basic godot default input mapping and custom simple movement
	if Input.is_action_pressed("ui_down"):
		velocity += Vector2.DOWN
	if Input.is_action_pressed("ui_up"):
		velocity += Vector2.UP
	if Input.is_action_pressed("ui_left"):
		velocity += Vector2.LEFT
	if Input.is_action_pressed("ui_right"):
		velocity += Vector2.RIGHT
	if Input.is_action_just_pressed("ui_select"):
		if right_hand_item != null:
			right_hand_item.uncarry()
			right_hand_item = null
		elif len(view_objects) != 0:
			print("yo")
			var obj_weight = view_objects[0].get_weight()
			if obj_weight <= strength and not view_objects[0].is_carried():
				print("yo1")
				if right_hand_item != null:
					print("yo2")
					right_hand_item.uncarry()
				right_hand_item = view_objects[0]
				view_objects[0].carried(right_hand)
				for snap_point in snapable_objects:
					if snap_point in view_objects[0].get_children():
						print("ok...")
						snapable_objects.erase(snap_point)
				view_objects.remove_at(0)
			
		
	velocity = velocity.normalized() * max_velocity
	
	if right_hand_item != null and "snapable" in right_hand_item.get_groups():
		if not right_hand_item.is_snapped():
			#print("search snap")
			for snap_point in snapable_objects:
				#print("still 2 steps")
				if right_hand.global_position.distance_squared_to(snap_point.global_position) < snap_dist_squared:
					#print("almost there")
					#print(snapable_objects)
					if right_hand_item.try_snap(snap_point):
						print("snapped")
						break
					else:
						snapable_objects.erase(snap_point)
		elif right_hand_item.global_position.distance_to(global_position) > snap_dist:
			right_hand_item.unsnap()
				
	move_and_slide()

func _on_interaction_view_body_entered(body: Node2D) -> void:
	if "carriable" in body.get_groups() and body not in view_objects:
		view_objects.append(body)

func _on_interaction_view_body_exited(body: Node2D) -> void:
	if body in view_objects:
		view_objects.erase(body)

func _on_interaction_view_area_entered(area: Area2D) -> void:
	if "snapable" in area.parent.get_groups() and area not in snapable_objects and area.parent != right_hand_item:
		#print("added snapable object")
		snapable_objects.append(area)

func _on_interaction_view_area_exited(area: Area2D) -> void:
	if area in snapable_objects:
		snapable_objects.erase(area)
