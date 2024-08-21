@tool
extends EditorInspectorPlugin

const button_decorator := preload("res://addons/decorators/decorators/button_decorator.gd")
const button2D_decorator := preload("res://addons/decorators/decorators/button2D_decorator.gd")
const button3D_decorator := preload("res://addons/decorators/decorators/button3D_decorator.gd")

var in_inspector: Array[Decorator]
var in_2D: Array[Decorator]
var in_3D: Array[Decorator]
var groups := {}

func _can_handle(object: Object) -> bool:
	in_inspector.clear()
	in_2D.clear()
	in_3D.clear()
	groups.clear()
	
	if not object or not object.get_script():
		return false
	
	var decos := Decorator.find_methods(object)
	
	for deco in decos:
		if deco.show_in_2D_inspector():
			in_2D.append(deco)
		
		if deco.show_in_3D_inspector():
			in_3D.append(deco)
		
		# Skip 2D and 3D.
		if not deco.show_in_inspector():
			continue
		
		if deco._can_handle(self):
			# If grouped, only handle updating the first.
			if deco.group_in_inspector():
				var group := deco._group
				if not group in groups:
					var gr: Array[Decorator] = []
					groups[group] = gr
					in_inspector.append(deco)
				groups[group].append(deco)
			else:
				in_inspector.append(deco)
	
	if object.has_method(&"_get_editor_buttons"):
		var items = object._get_editor_buttons()
		# In case a single method name or method was passed.
		if not items is Array:
			items = [items]
		
		for item in items:
			if item is Array:
				#buttons.append(InspectorButtonRow.new(obj, item))
				pass # TODO
			else:
				match typeof(item):
					TYPE_STRING:
						var btn := button_decorator.new()
						btn.object = object
						btn.method = item
						btn._group = item
						in_inspector.append(btn)
					
					TYPE_CALLABLE:
						var btn := button_decorator.new()
						btn.object = object
						var callable: Callable = item
						btn.callable = item
						btn.label = callable.get_method().capitalize()
						btn._group = callable.get_method()
						in_inspector.append(btn)
					
					TYPE_DICTIONARY:
						var dict: Dictionary = item
						var deco: Decorator
						match dict.get("type"):
							"2D":
								deco = button2D_decorator.new()
								in_2D.append(deco)
							"3D":
								deco = button3D_decorator.new()
								in_3D.append(deco)
							_:
								deco = button_decorator.new()
								in_inspector.append(deco)
						deco.object = object
						deco.color = dict.get("tint", deco.color)
						deco.tooltip = dict.get("tooltip", deco.tooltip)
						
						var call = dict.get("call")
						match typeof(call):
							TYPE_STRING:
								deco.method = call
								deco.label = dict.get("text", call.capitalize())
								deco._group = call
							TYPE_CALLABLE:
								deco.callable = call
								deco.label = dict.get("text", call.get_method().capitalize())
								deco._group = call.get_method()
					
					_:
						push_error("HMM?", item)
	
	return len(in_inspector) > 0

func get_group(deco: Decorator) -> Array[Decorator]:
	if deco._group not in groups:
		var out: Array[Decorator]
		out.append(deco)
		return out
	return groups[deco._group]

func _parse_begin(object: Object) -> void:
	for deco in in_inspector:
		deco._parse_begin(self)

func _parse_category(object: Object, category: String) -> void:
	for deco in in_inspector:
		deco._parse_category(self, category)

func _parse_end(object: Object) -> void:
	for deco in in_inspector:
		deco._parse_end(self)

func _parse_group(object: Object, group: String) -> void:
	for deco in in_inspector:
		deco._parse_group(self, group)

func _parse_property(object: Object, type: Variant.Type, name: String, hint_type: PropertyHint, hint_string: String, usage_flags: int, wide: bool) -> bool:
	var remove_builtin := false
	for deco in in_inspector:
		if deco._parse_property(self, type, name, hint_type, hint_string, usage_flags, wide):
			remove_builtin = true
	return remove_builtin
