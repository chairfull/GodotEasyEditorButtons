@tool
extends Resource
class_name CodeScratchPad
## Scratchpad for testing code.

@export_custom(PROPERTY_HINT_EXPRESSION, "") var head := ""
@export_custom(PROPERTY_HINT_EXPRESSION, "") var code := ""

static func _get_editor_buttons():
	return ["run", "print_source_code", "copy_to_clipboard"]

func copy_to_clipboard():
	DisplayServer.clipboard_set(get_source_code())

func get_source_code() -> String:
	var lines := ["@tool"]
	lines.append("extends Object")
	
	for key in get_meta_list():
		lines.append("var %s: %s" % [key, type_string(typeof(get_meta(key)))])
	
	lines.append(head)
	lines.append("func _test_code():")
	lines.append("\t" + code.replace("\n", "\n\t"))
	lines.append("\tpass") # Just in case code was left blank.
	
	return "\n".join(lines)

func print_source_code():
	print(get_source_code())

func run():
	var source_code := get_source_code()
	var script := GDScript.new()
	script.source_code = source_code
	script.reload()
	
	var obj := Object.new()
	obj.set_script(script)
	
	for key in get_meta_list():
		obj[key] = get_meta(key)
	
	var result = obj._test_code()
	
	# Copy properties back from the object.
	for key in get_meta_list():
		set_meta(key, obj[key])
	
	print_rich("[b]Returned: [/b][color=green]%s[/color]" % [result])
