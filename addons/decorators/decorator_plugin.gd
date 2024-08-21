@tool
extends EditorPlugin

var plugin: EditorInspectorPlugin

func recurs(n: Node, c: Callable):
	c.call(n)
	for ch in n.get_children():
		recurs(ch, c)

var inspector2D := HBoxContainer.new()
var inspector3D := HBoxContainer.new()

func _enter_tree() -> void:
	var main_screen := EditorInterface.get_editor_main_screen()
	
	var editor3D := main_screen.find_child("*Node3DEditor*", true, false)
	var hflow3D := editor3D.find_child("*HFlowContainer*", true, false)
	inspector3D.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inspector3D.alignment = BoxContainer.ALIGNMENT_END
	inspector3D.add_to_group(&"inspector3D")
	hflow3D.add_child(inspector3D)
	
	var editor2D := main_screen.find_child("*CanvasItemEditor*", true, false)
	var hflow2D := editor2D.find_child("*HFlowContainer*", true, false)
	inspector2D.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inspector2D.alignment = BoxContainer.ALIGNMENT_END
	inspector2D.add_to_group(&"inspector2D")
	hflow2D.add_child(inspector2D)
	
	#EditorInterface.get_inspector().object_id_selected.connect(_object_id_selected)
	EditorInterface.get_inspector().edited_object_changed.connect(_edited_object_changed)
	
	# 
	plugin = preload("res://addons/decorators/decorator_inspector.gd").new()
	add_inspector_plugin(plugin)

#func _object_id_selected(id: int):
	#prints("Selected", id, instance_from_id(id))

func _edited_object_changed():
	# Remove custom 2D canvas controls.
	for node in get_tree().get_nodes_in_group(&"decorator_button"):
		node.queue_free()
	
	# Attempt to add this objects controls.
	var object := EditorInterface.get_inspector().get_edited_object()
	if object:
		for deco in plugin.in_2D:
			if deco.show_in_2D_inspector():
				deco.add_to_2D_inspector(inspector2D)
		
		for deco in plugin.in_3D:
			if deco.show_in_3D_inspector():
				deco.add_to_3D_inspector(inspector3D)
		
		# Add all to group for easier removal.
		for child in inspector2D.get_children() + inspector3D.get_children():
			child.add_to_group(&"decorator_button")
	
func _exit_tree() -> void:
	inspector2D.queue_free()
	inspector3D.queue_free()
	
	remove_inspector_plugin(plugin)
