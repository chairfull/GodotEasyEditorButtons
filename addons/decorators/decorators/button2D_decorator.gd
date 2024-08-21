@tool
extends Decorator

var label := ""
var color := Color.WHITE
var tooltip := ""

func _init(label := "") -> void:
	self.label = label

func show_in_2D_inspector() -> bool:
	return true

func add_to_2D_inspector(node: Node):
	var btn := Button.new()
	btn.text = label if label else method.capitalize()
	btn.tooltip_text = tooltip if tooltip else get_method_comment()
	btn.pressed.connect(get_method())
	btn.self_modulate = color
	node.add_child(btn)
