extends Node2D
class_name PipelineSystem

var pipelines: Array[PipelineTransport] = []
var inputs: Array[PipelineDonator]
var outputs: Array[PipelineTransport] = []:
	get:
		return outputs
var leaks: Array[SnapPoint] = []

func add_output(output: Pipeline) -> void:
	if output not in outputs:
		output.system = self
		pipelines.append(output)
		outputs.append(output)
		
func del_output(output: Pipeline) -> void:
	outputs.erase(output)

func add_leak(leak: SnapPoint) -> void:
	if leak not in leaks:
		leaks.append(leak)
		
func del_leak(leak: SnapPoint) -> void:
	leaks.erase(leak)
	
func del_part(part, system= get_system()) -> void:
	if part is PipelineDonator:
		system[0].erase(part)
	elif part is SnapPoint:
		system[1].erase(part)
	elif part is PipelineTransport:
		system[2].erase(part)
		system[3].erase(part)
	
	update_pipeline_system()
		
func update_pipeline_system() -> void:
	for pipeline in pipelines:
		if pipeline is Pipeline:
			pipeline.system = null
	if len(inputs) == 0:
		queue_free()
		return
	
	var new_pipelines: Array[PipelineTransport] = []
	var new_inputs: Array[PipelineDonator] = [inputs[0]]
	var new_outputs: Array[PipelineTransport] = []
	var new_leaks: Array[SnapPoint] = []
	var new_system = [new_inputs, new_leaks, new_pipelines,new_outputs]
	var neighbors: Array[Pipeline] = [inputs[0]]
	inputs[0].system = self
	
	# Depth-First-Search TODO
	while len(neighbors) != 0:
		var new_neighbors = neighbors[-1].get_open_outputs()
		var i: int = 0
		while i < len(new_neighbors):
			if not check_part(new_neighbors[i], new_system):
				add_part(new_neighbors[i], new_system)
				if new_neighbors[i] is SnapPoint:
					new_neighbors.remove_at(i)
					i-=1
				else:
					new_neighbors[i].system = self
				i += 1
			else: 
				new_neighbors.remove_at(i)
		if len(new_neighbors) == 0:
			neighbors.remove_at(len(neighbors)-1)
		else:
			neighbors.append_array(new_neighbors)
	
	inputs = new_inputs
	pipelines = new_pipelines
	leaks = new_leaks
	outputs = new_outputs
		
func check_part(part, system = get_system()) -> bool:
	if part is PipelineDonator:
		if part in system[0]:
			return true
	elif part is SnapPoint:
		if part in system[1]:
			return true
	elif part is PipelineTransport:
		if part in system[2]:
			return true
	return false

func add_part(part, system = get_system()) -> void:
	if part is PipelineDonator:
		system[0].append(part)
	elif part is SnapPoint:
		system[1].append(part)
	elif part is PipelineTransport:
		system[2].append(part)
	else:
		print("WARNING, invalid object infiltrated pipeline system")

func get_system() -> Array:
	return [inputs, leaks, pipelines, outputs]

func merge_with(system: PipelineSystem) -> void:
	for output in system.get_outputs():
		if output in outputs:
			print("WARNING: Doubled System Pipe Connection")
		add_output(output)
		
func merge_to(system: PipelineSystem) -> void:
	system.merge_with(self)
	self.queue_free()

func drop_liquid(point: SnapPoint, liquid: Liquid) -> void:
	var already_existend_liquid = await point.check_liquid()
	if already_existend_liquid == null:
		add_child(liquid)
		for i in range(5):
			await get_tree().process_frame
		liquid.place_at(point.point_pos)
	else:
		already_existend_liquid.add(liquid)

func receive_liquid(source: PipelineDonator, liquid: Liquid) -> void:
	var vol = liquid.volume
	var out_amount = len(outputs)
	
	for leak in leaks: ## TODO: Leak update after removing Pipeline not done
		drop_liquid(leak, liquid.take((vol/2)/len(leaks)))
	
	vol = liquid.volume
	
	for pipeline in outputs:
		var not_sent: Liquid = pipeline.receive_liquid(liquid.take(vol/out_amount))
		var not_sent_vol = 0
		if not_sent != null:
			liquid.add(not_sent)
			not_sent_vol = not_sent.volume
		out_amount -= 1
		
		if out_amount == 0:
			vol = not_sent_vol
		else:
			vol -= vol/out_amount - not_sent_vol
		
		if not_sent_vol > 0:
			del_output(pipeline)
			for new_out in pipeline.get_open_outputs():
				if new_out is PipelineTransport and new_out not in pipelines:
					add_output(new_out)
				elif new_out is SnapPoint:
					add_leak(new_out)
