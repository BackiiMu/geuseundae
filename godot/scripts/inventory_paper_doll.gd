extends Control

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _draw() -> void:
	# The ornate body diagram is baked into the production UI skin. This node
	# remains as the coordinate surface for live equipment buttons only.
	pass
