extends Resource
class_name Decorator
## Python style wrappers for functions.
##	# How to use:
##	- Create a script myname_decorator.gd
##	- Add #@myname above any function.
##	- Use `Decorator.find_methods(object, load("res://myname_decorator.gd"))` for a list.
##	- Optionally can accept arguments: #@myname(true, "id")
##	- Optionally write a `class_name myname` so you can do: `Decorator.find_methods(object, myname)`.

var object: Object
var method: String
var callable: Callable
var property: String
var _group: String
var _source_line_deco := -1
var _source_line_meth := -1
var _source_line_prop := -1

func is_method() -> bool:
	return method != "" or callable

func is_property() -> bool:
	return property != ""

func get_method() -> Callable:
	return callable if callable else Callable(object, method)

func get_value() -> Variant:
	return object.get(property)

func set_value(value: Variant):
	object.set(property, value)

## Goes upwards from the function, collecting comments until it hit's a space or decorator.
func get_method_comment() -> String:
	if _source_line_meth != -1:
		return _collect_comments(_source_line_meth)
	return ""

func get_decorator_comment() -> String:
	if _source_line_deco != -1:
		return _collect_comments(_source_line_deco)
	return ""

func _collect_comments(from: int) -> String:
	if from == 0:
		return ""
	var sc: GDScript = object.get_script()
	var lines := sc.source_code.split("\n")
	var comment := []
	# Grab comment that may exist on same line as function.
	var f := lines[from].find("##")
	if f != -1:
		comment.push_front(lines[from].substr(f+2).trim_prefix(" "))
	# Go up until you hit a non comment.
	var i := from-1
	while i >= 0 and lines[i].begins_with("##"):
		comment.push_front(lines[i].trim_prefix("##").trim_prefix(" "))
		i -= 1
	return "\n".join(comment)

#func get_id() -> String:
	#return get_script().resource_path.get_basename().get_file().trim_suffix("_decorator")
#
#func get_group() -> String:
	#return "%s:%s" % [method, get_id()]

#region 2D Canvas calls.

func show_in_2D_inspector() -> bool:
	return false

func add_to_2D_inspector(node: Node):
	pass

#endregion

#region 3D Canvas calls.

func show_in_3D_inspector() -> bool:
	return false

func add_to_3D_inspector(node: Node):
	pass

#endregion

#region EditorInspector calls.

func show_in_inspector() -> bool:
	return false

## When multiple decorators of the same type share a method they can be called in one go.
## If true, use ed.get_group(self) to get siblings.
func group_in_inspector() -> bool:
	return false

func _can_handle(ed: EditorInspectorPlugin) -> bool:
	return true

func _parse_begin(ed: EditorInspectorPlugin) -> void:
	pass

func _parse_category(ed: EditorInspectorPlugin, category: String) -> void:
	pass

func _parse_end(ed: EditorInspectorPlugin) -> void:
	pass

func _parse_group(ed: EditorInspectorPlugin, group: String) -> void:
	pass

func _parse_property(ed: EditorInspectorPlugin, type: Variant.Type, name: String, hint_type: PropertyHint, hint_string: String, usage_flags: int, wide: bool) -> bool:
	return false

#endregion

func _to_string() -> String:
	var dname = get_script().resource_path.get_basename().get_file().trim_suffix("_decorator")
	var dargs := ", ".join(get_property_list()\
		.filter(func(x): return not x.name.begins_with("_") and not x.name in ["object", "method", "property"] and x.usage & PROPERTY_USAGE_SCRIPT_VARIABLE != 0)\
		.map(func(x): return "%s=%s" % [x.name, self[x.name]]))
	return "%s(%s)" % [dname, dargs]

#region Static.

static func _arg_str_to_args(input: String, object: Object) -> Array:
	var reg := RegEx.create_from_string(r'\[([^[\]]*+(?:(?R)[^[\]]*+)*+)\]|\{([^{}]*)\}|[^,\[\]\{\}]+')
	var args := []
	for item: RegExMatch in reg.search_all(input):
		var arg := item.strings[0].strip_edges()
		if arg:
			args.append(_arg_to_var(arg, object))
	return args

static func _arg_to_var(input: String, object: Object) -> Variant:
	if input.begins_with("Color."):
		return Color(input.trim_prefix("Color."))
	else:
		var exp := Expression.new()
		exp.parse(input)
		return exp.execute([], object)

static func find_methods(object: Object) -> Array[Decorator]:
	var out: Array[Decorator] = []
	if not Engine.is_editor_hint():
		return out
	
	var gdscript: Script = object.get_script()
	if not gdscript:
		return out
	
	var is_tool := gdscript.source_code.begins_with("@tool")
	
	var lines := gdscript.source_code.split("\n")
	for i in len(lines):
		var line := lines[i]
		if line.begins_with("#@"):
			var deco_type := line.trim_prefix("#@").split("(", true, 1)[0]
			var deco_line := i
			var deco_args := []
			var method := ""
			var method_line := -1
			
			# Get args.
			if "(" in line:
				var inner := line.split("(", true, 1)[-1].rsplit(")", true, 1)[0]
				deco_args = _arg_str_to_args(inner, object)
			
			# Look ahead for a function.
			var j := i + 1
			while j < len(lines):
				if lines[j].begins_with("func "):
					method = lines[j].trim_prefix("func ").split("(", true, 1)[0]
					method_line = j
					break
				j += 1
			
			var scr: GDScript = get_class_script(deco_type + "_decorator")
			if not scr and not deco_type.begins_with("#@export"):
				push_warning("No decorator @%s." % [deco_type])
				continue
			
			var dec: Decorator = create(scr, deco_args)
			dec.object = object
			dec.method = method
			dec._group = method
			dec._source_line_deco = deco_line
			dec._source_line_meth = method_line
			out.append(dec)
	
	if out and not is_tool:
		push_error("Decorators only work on @tool scripts.")
		return []
	
	return out

# TODO: cache this?
static func get_class_script(classname: String) -> Script:
	var file := "res://addons/decorators/decorators/%s.gd" % classname
	if FileAccess.file_exists(file):
		return load(file)
	
	if ClassDB.class_exists(classname):
		return ClassDB.instantiate(classname)
	
	for item in ProjectSettings.get_global_class_list():
		if item.class == classname:
			return load(item.path)
	
	return

static func create(sc: Script, args: Array) -> Object:
	match len(args):
		0: return sc.new()
		1: return sc.new(args.pop_front())
		2: return sc.new(args.pop_front(), args.pop_front())
		3: return sc.new(args.pop_front(), args.pop_front(), args.pop_front())
		4: return sc.new(args.pop_front(), args.pop_front(), args.pop_front(), args.pop_front())
	push_error("Not implemented for arg count %s." % [len(args)])
	return

#endregion
