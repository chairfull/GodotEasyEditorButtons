@tool
extends EditorPlugin

const Decorator := preload("Decorator.gd")

var plugin: EditorInspectorPlugin
var inspector2D := HBoxContainer.new()
var inspector3D := HBoxContainer.new()
var menu: Node
var popups: Array[PopupMenu]
var decorators: Array[Decorator]

const editor_menubar_decorator = preload("decorators/editor_menubar_decorator.gd")

func _id_pressed(id: int):
	decorators[id].get_method().call()

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
	
	# Custom editor buttons.
	menu = EditorInterface.get_base_control().find_child("*MenuBar*", true, false)
	
	decorators.clear()
	
	# Scan all scripts for #@editor_menubar on a static function.
	var decos := []
	for file in get_files("res://", ".gd"):
		if "#@editor_menubar" in FileAccess.get_file_as_string(file):
			var script := load(file)
			var rank := 0
			for item in Decorator.find_methods(script):
				if item is editor_menubar_decorator:
					item.rank = rank + item.rank * 1000
					decos.append(item)
					rank += 1
	# Sort.
	decos.sort_custom(func(a, b): return a.rank < b.rank)
	# Populate.
	for item in decos:
		_add_menubar_item(item)
	
	EditorInterface.get_inspector().edited_object_changed.connect(_edited_object_changed)
	
	plugin = preload("res://addons/decorators/decorator_inspector.gd").new()
	add_inspector_plugin(plugin)

func _exit_tree() -> void:
	inspector2D.queue_free()
	inspector3D.queue_free()
	for popup in popups:
		popup.queue_free()
	
	remove_inspector_plugin(plugin)

func _add_menubar_item(item: editor_menubar_decorator):
	var label: String = item.method.capitalize()
	var path: String = item.path
	if path.begins_with("/"):
		path = path.trim_prefix("/")
	else:
		path = "Custom".path_join(label)
	
	var parts := path.split("/")
	label = parts[-1]
	
	var pops = menu
	for i in len(parts)-1:
		var part: String = parts[i]
		var next := pops.get_node_or_null(part)
		if not next:
			next = PopupMenu.new()
			next.name = part
			next.id_pressed.connect(_id_pressed)
			next.add_to_group("editor_menubar_popup")
			popups.append(next)
			if pops == menu:
				pops.add_child(next)
			else:
				pops.add_submenu_node_item(part, next)
		pops = next
	
	if item.seperator:
		(pops as PopupMenu).add_separator(label)
	else:
		if item.icon:
			var icon = load(item.icon) if item.icon is String else item.icon
			pops.add_icon_item(icon, label, len(decorators))
		else:
			pops.add_item(label, len(decorators))
	
		decorators.append(item)

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

func recurs(n: Node, c: Callable):
	c.call(n)
	for ch in n.get_children():
		recurs(ch, c)

static func get_files(dir: String, tail := "") -> Array[String]:
	var files: Array[String] = []
	if DirAccess.dir_exists_absolute(dir):
		for file in DirAccess.get_files_at(dir):
			if not tail or file.ends_with(tail):
				files.append(dir.path_join(file))
		for dir2 in DirAccess.get_directories_at(dir):
			files.append_array(get_files(dir.path_join(dir2), tail))
	return files
