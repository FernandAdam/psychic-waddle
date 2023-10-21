extends Area2D
class_name SnapPoint

@export var snap_direction = 0 # given in degree, 0 = right
@export var snap_partner: SnapPoint = null
@onready var parent: Pipeline = get_parent().get_parent()

var point_pos:
	get:
		return get_children()[0].global_position

func get_partner() -> SnapPoint:
	return snap_partner
	
func set_partner(partner: SnapPoint) -> void:
	var old_partner: SnapPoint = snap_partner
	snap_partner = partner
	
	if partner == null:
		monitorable = true
		show()
		if old_partner != null:
			parent.unsnap_obj(old_partner.parent)
			old_partner.set_partner(null)
	else:
		monitorable = false
		hide()
		parent.snap_to(snap_partner.parent)
		if parent.system != null:
			parent.system.del_leak(self)
		if snap_partner.get_partner() != self:
			snap_partner.set_partner(self)
		
func check_partner():
	if snap_partner == null:
		print("connection " + str(snap_direction) + "check")
		for i in range(5):
			await get_tree().process_frame
		print(get_overlapping_areas())
		for area in get_overlapping_areas():
			print("check extra partner")
			if area is SnapPoint:
				print("found extra partner")
				area.set_partner(self)
				
func check_liquid() -> Liquid:
	if (snap_partner != null):
		push_error("Partner is not null")
	
	for i in range(5):
		await get_tree().process_frame
	
	for body in get_overlapping_bodies():
		if body is Liquid:
			return body
	
	return null

func rotate_rad(rad: float) -> void:
	snap_direction -= int(rad/PI*180)
