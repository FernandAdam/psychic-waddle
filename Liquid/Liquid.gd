extends CharacterBody2D
class_name Liquid

@onready var sprite = $Sprite2D
@onready var polygon = $SubViewport/Polygon2D
@onready var skeleton = $SubViewport/Polygon2D/Skeleton2D
@onready var col_shape = $CollisionShape2D
@onready var sm: StateChart = $StateChart
var state = "Transferred"
var rect: 
	set(size):
		sprite.region_rect = Rect2(0,0, size.x, size.y)
		#polygon.scale = Vector2(0.01, 0.01)# Vector2(1,1)*size/128
	get:
		return null
		return sprite.get_rect()

var checking_size = true
var volume: float = 0: # given in litres
	set(val):
		#print(state)
		if abs(val)>100:
			return
		volume = val
		if state == "Free":
			var bones: Array[Node] = skeleton.get_children()
			var pol_size = get_polygon_size()
			print(pol_size)
			var diff = pol_size-volume*1500
			print(diff)
			if abs(diff) > 1000:
				print("Correcting Water size")
				if checking_size:
					checking_size = false
					var randi = randi()%len(bones)
					var bonescale = bones[randi].scale.x
					bones[randi].scale.x -= diff/2000
					bones[randi].scale.x = max(bones[randi].scale.x,0)
					for i in range(5):
						await get_tree().process_frame
					diff = get_polygon_size()-volume*1000
					checking_size = true
			#pass
var density: float = 1 # given in kilograms per litres

var weight: float = 0:
	get:
		return volume * density
		
func get_polygon_size() -> float:
	#assert(polygon != null)
	#print(get_node("."))
	var pointArray = [] #polygon.polygon
	
	var mod_bones = skeleton.get_children()
	#print(mod_bones)
	for i in len(mod_bones):
		pointArray.append(mod_bones[i].global_position 
			+ (Vector2.from_angle(mod_bones[i].get_bone_angle())) * mod_bones[i].get_length() * mod_bones[i].scale.x)
	var volume: float = 0
	
	# got it from here https://www.wikihow.com/Calculate-the-Area-of-a-Polygon
	for i in len(pointArray):
		volume += pointArray[i][0]*pointArray[(i+1)%len(pointArray)][1]
		
	for i in len(pointArray):
		volume -= pointArray[i][1]*pointArray[(i+1)%len(pointArray)][0]
	
	return abs(volume/2)

func _ready() -> void:
	print(get_polygon_size())
	var bones: Array[Node] = get_node("SubViewport/Polygon2D/Skeleton2D").get_children()
	for bone in bones:
		bones[randi()%len(bones)].scale.x += ((randi()%10)-5)
		

func take(amount: float) -> Liquid:
	var res_vol = volume - amount
	assert(res_vol>=0)
	
	volume = res_vol
	
	var took_liq = load("res://Liquid/Liquid.tscn").instantiate()
	#add_sibling(took_liq)
	took_liq.position = position
	took_liq.density = density
	took_liq.volume = amount
	if volume < 0.0001:
		queue_free()
	return took_liq

func add(liq: Liquid) -> void:
	density = (volume*density + liq.volume*liq.density) / (volume+liq.volume)
	volume += liq.volume
	liq.queue_free()
	
func place_at(pos: Vector2):
	rect = Vector2(sqrt(volume),sqrt(volume))
	sprite.get_material().set_shader_parameter("volume", sqrt(volume)/2)
	global_position = pos
	#while not sm._state.active:
	sm.send_event("place")
	
	
func _process(delta: float) -> void:
	rect = Vector2(sqrt(volume), sqrt(volume))
	sprite.get_material().set_shader_parameter("volume", sqrt(volume)/2)
	#rotation+=0.2


func _on_transferred_state_entered() -> void:
	state = "Transferred"

func _on_free_state_entered() -> void:
	state = "Free"
