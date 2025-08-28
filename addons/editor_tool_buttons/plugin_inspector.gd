@tool
extends EditorInspectorPlugin

const Decorator := preload("decorator.gd")
const DecoButton := preload("deco_button.gd")
const DecoButton2D := preload("deco_button2d.gd")
const DecoButton3D := preload("deco_button3d.gd")

var target: Object
var in_inspector: Array[Decorator] ## Showin in inspector panel.
var in_2D: Array[Decorator] ## Shown in 2d editor.
var in_3D: Array[Decorator] ## Shown in 3d editor.
var groups := {}

func _can_handle(object: Object) -> bool:
	in_inspector.clear()
	in_2D.clear()
	in_3D.clear()
	groups.clear()
	
	if not object or not object.get_script():
		return false
	
	var obj_decos: Array[Decorator]
	if object.has_method(&"_get_editor_buttons"):
		var items = object._get_editor_buttons()
		# In case a single method name or method was passed.
		if typeof(items) != TYPE_ARRAY:
			items = [items]
		
		var group_index := 0
		for item in items:
			if item is Array:
				for subitem in item:
					var deco := _generate(object, subitem)
					deco._group = "hor_%s" % group_index
					obj_decos.append(deco)
				group_index += 1 
			else:
				var deco := _generate(object, item)
				obj_decos.append(deco)
	
	var scr_decos := Decorator.find_methods(object)
	var decos := obj_decos + scr_decos
	
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
	
	target = object
	return in_inspector.size() > 0

func _generate(object: Object, item: Variant) -> Decorator:
	match typeof(item):
		TYPE_STRING:
			var btn := DecoButton.new()
			btn.object = object
			btn.method = item
			btn._group = item
			return btn
		
		TYPE_CALLABLE:
			var btn := DecoButton.new()
			btn.object = object
			var callable: Callable = item
			btn.callable = item
			btn.label = callable.get_method().capitalize()
			btn._group = callable.get_method()
			return btn
		
		TYPE_DICTIONARY:
			var dict: Dictionary = item
			var btn: Decorator
			match str(dict.get("type", "")).to_lower():
				"2d": btn = DecoButton2D.new()
				"3d": btn = DecoButton3D.new()
				_: btn = DecoButton.new()
			btn.object = object
			btn.color = dict.get("tint", btn.color)
			btn.tooltip = dict.get("tooltip", btn.tooltip)
			btn.kwargs = dict
			
			var call = dict.get("call")
			match typeof(call):
				TYPE_STRING:
					btn.method = call
					btn.label = dict.get("text", call.capitalize())
					btn._group = call
				TYPE_CALLABLE:
					btn.callable = call
					btn.label = dict.get("text", call.get_method().capitalize())
					btn._group = call.get_method()
			return btn
		_:
			push_error("HMM?", item)
	return null

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
