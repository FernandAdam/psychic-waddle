extends Node2D

@onready var camera: Camera2D = $Camera2D
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$StateChartDebugger.debug_node($PipelineTransport2.sm)
	$StateChartDebugger2.debug_node($PipelineDonatorMechanicalWell.sm)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_released("scroll_down"):
		camera.zoom -= Vector2(0.1,0.1)
	elif Input.is_action_just_released("scroll_up"):
		camera.zoom += Vector2(0.1,0.1)
