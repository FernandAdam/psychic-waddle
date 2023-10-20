extends Pipeline
class_name PipelineDonator

@onready var timer: Timer = $Timer
@export var output_flow: float = 60 # given in litres per second
@export var output_delay: float = 0.5


func _on_connected_state_entered() -> void:
	sm.send_event("fill")
	
	
func _on_used_state_entered() -> void:
	timer.start(output_delay)
	system = load("res://PipelineSystem/PipelineSystem.tscn").instantiate()
	add_sibling(system)
	system.add_part(self)
	for out in snapped_to:
		system.add_output(out)
	
func _on_used_state_exited() -> void:
	timer.stop()
	system = null
	

func _on_timer_timeout() -> void:
	#print("SENDING WATER")
	content.volume += output_flow*output_delay
	var send_vol = content.volume - max_volume
	if send_vol > 0:
		system.receive_liquid(self, content.take(send_vol))
