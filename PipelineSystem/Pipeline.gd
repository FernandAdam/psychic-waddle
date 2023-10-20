extends CharacterBody2D
class_name Pipeline

var carried_by
var snapped_to: Array[Pipeline]
var system: PipelineSystem = null:
	set(new_system):
		system = new_system
	get:
		return system

@export var empty_weight: float = 20 # given in kilograms
@export var max_volume: float = 20 # given in litres

@onready var content: Liquid = $Liquid
var placed_pos: Vector2

@onready var snap_points: Array[Area2D] = []
@onready var sprite: Sprite2D = $Sprite2D
@onready var sm: StateChart = $PipelineStateChart
@onready var shader: Material = $Sprite2D.get_material()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	placed_pos = global_position
	
	# initializing SnapPoints
	
	for snap_point in $SnapPoints.get_children():
		print("trying to add initial SnapPoint: " + str(snap_point))
		if snap_point is SnapPoint:
			print("adding initial SnapPoint: " + str(snap_point))
			snap_points.append(snap_point)
	
	uncarry()
	unsnap()
	add_to_group("carriable")
	add_to_group("snapable")

func get_weight() -> float:
	return empty_weight + content.weight
	
func is_carried() -> bool:
	return carried_by != null
	
func uncarry() -> void:
	carried_by = null
	sm.send_event("place")
	sm.set_expression_property("carried_by", carried_by)
	
func carried(obj) -> void:
	carried_by = obj
	sm.send_event("unsnap")
	sm.send_event("carry")
	sm.set_expression_property("carried_by", carried_by)
	
	
func is_snapped() -> bool:
	return snapped_to != []
	
func unsnap() -> void:
	for snap_point in snap_points:
		snap_point.set_partner(null)
	snapped_to = []
	
	if system != null:
		system.del_part(self)
		system = null
	sm.set_expression_property("snapped_to", snapped_to)
	sm.send_event("unsnap")
	
func unsnap_obj(obj: Pipeline) -> void:
	snapped_to.erase(obj)
	
	sm.set_expression_property("snapped_to", snapped_to)
	sm.send_event("unsnap")
	
func snap_to(obj: Pipeline) -> void:
	snapped_to.append(obj)
	if system != null:
		system.add_output(obj)
	sm.send_event("snap")
	sm.set_expression_property("snapped_to", snapped_to)
	
func try_snap(obj: SnapPoint) -> bool:
	# check if someone used old area data
	print("trying to snap")
	if obj.parent == self:
		return false
	
	# main snap check
	for snap_point in snap_points:
		if (snap_point.snap_direction+180)%360 == obj.snap_direction:
			placed_pos = obj.global_position + Vector2.from_angle(-PI/180*obj.snap_direction) * 32
			#snapped_to.append(obj.get_parent())
			#obj.get_parent().snap_to(self)
			obj.set_partner(snap_point)
			sm.send_event("snap")
			sm.set_expression_property("snapped_to", snapped_to)
			return true 
	return false
	
###
### Liquid System part
###

func receive_liquid(liquid: Liquid) -> Liquid:
	sm.send_event("fill")
	content.add(liquid)
	if content.volume > max_volume:
		return content.take(content.volume - max_volume)
	return null
	
func send_liquid(to: Pipeline, amount: float) -> Liquid:
	var content_part = content.take(amount)
	return to.receive_liquid(content_part)
		
func get_open_outputs() -> Array[Node2D]: # returns an array of SnapPoints(Area2D) and PipelineTransports(Character2D)
	var outputs: Array[Node2D] = []
	for potential_out in snapped_to:
		if potential_out.system != system:
			outputs.append(potential_out)
	
	for snap_point in snap_points:
		if snap_point.get_partner() == null:
			outputs.append(snap_point)
			
	return outputs
###
### State Chart Part
###

func _on_hold_state_entered() -> void:
	unsnap()

func _on_hold_state_physics_processing(delta) -> void:
	global_position = carried_by.global_position

func _on_hold_state_exited() -> void:
	pass # Replace with function body.

func _on_snapped_state_entered() -> void:
	global_position = placed_pos
	for snap_point in snap_points:
		print("checking other snapPoints")
		# to connect to every other existing snap_point
		snap_point.check_partner()

func _on_snapped_state_physics_processing(delta) -> void:
	pass # Replace with function body.

func _on_snapped_state_exited() -> void:
	pass
	
func _on_placed_state_entered() -> void:
	pass # Replace with function body.

func _on_placed_state_physics_processing(delta) -> void:
	pass # Replace with function body.

func _on_placed_state_exited() -> void:
	pass # Replace with function body.

func _on_connected_state_entered() -> void:
	pass # Replace with function body.

func _on_connected_state_physics_processing(delta) -> void:
	pass # Replace with function body.

func _on_connected_state_exited() -> void:
	pass

func _on_used_state_entered() -> void:
	pass # Replace with function body.

func _on_used_state_physics_processing(delta) -> void:
	"""
	var flow_out = []
	#for snap_point in snap_points:
	#	if snap_point.get_partner() == null:
	#		flow_out.append(snap_point)
	
	for pipeline in snapped_to:
		if pipeline not in flow_table.keys():
			flow_out.append(pipeline)
		
	var sendable_volume: float = 0
	for pipeline in flow_table:
		content.add_liquid(flow_table)
		sendable_volume += flow_table[pipeline].volume
	
	if content.volume > max_volume:
		sendable_volume += content.volume - max_volume
		content.volume = max_volume
	
	for end in flow_out:
		if end is SnapPoint:
			drop_liquid(end, sendable_volume/len(flow_out))
		elif end is Pipeline:
			send_liquid(end, sendable_volume/len(flow_out))
	"""
		
	shader.set_shader_parameter("volume", content.volume)
	shader.set_shader_parameter("max_volume", max_volume)
	sm.set_expression_property("volume", content.volume)
	sm.set_expression_property("max_volume", max_volume)

func _on_used_state_exited() -> void:
	pass # Replace with function body.
