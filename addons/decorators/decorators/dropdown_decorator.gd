@tool
extends "../decorator.gd"

var items_variant: Variant
var split_join := "/"
var items: Array

func _init(il: Variant, sj := "/"):
	split_join = sj
	items_variant = il
	
func get_items() -> Array:
	items = []
	match typeof(items_variant):
		TYPE_STRING:
			match items_variant:
				"METHODS":
					for minfo in object.get_method_list():
						items.append(minfo.name)
				"PROPERTIES":
					for pinfo in object.get_property_list():
						if pinfo.usage & PROPERTY_USAGE_SCRIPT_VARIABLE != 0:
							items.append(pinfo.name)
				"SIGNALS":
					for sinfo in object.get_signal_list():
						items.append(sinfo.name)
				_:
					var exp := Expression.new()
					if exp.parse(items_variant) == OK:
						var got = exp.execute([], object)
						if got is Array:
							items = got
						else:
							push_error("DD: \"%s\" got %s instead of an array." % [items_variant, got])
					else:
						push_error(exp.get_error_text())
		
		TYPE_ARRAY, TYPE_PACKED_STRING_ARRAY:
			items = items_variant
		
		TYPE_DICTIONARY:
			_recurse("", items_variant, items)
	
	return items
	
func _recurse(head: String, dict: Dictionary, items: Array):
	for key in dict:
		var path := str(key) if not head else "%s%s%s" % [head, split_join, key]
		items.append(path)
		if typeof(dict[key]) == TYPE_DICTIONARY:
			_recurse(path, dict[key], items)

func show_in_inspector() -> bool:
	return true

func _parse_property(ed: EditorInspectorPlugin, type: Variant.Type, name: String, hint_type: PropertyHint, hint_string: String, usage_flags: int, wide: bool) -> bool:
	if name == property:
		var ep := EditorProperty.new()
		ep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var hbox := HBoxContainer.new()
		ep.add_child(hbox)
		hbox.name = "hbox"
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var le := LineEdit.new()
		hbox.add_child(le)
		le.name = "line_edit"
		le.text = ed.target[property]
		le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var mb := MenuButton.new()
		hbox.add_child(mb)
		mb.text = "..."
		mb.flat = false
		var op := mb.get_popup()
		op.min_size.x = 100
		#HACK? WTF? On pressed.
		op.id_pressed.connect(_id_pressed.bind(ed, le))
		
		# Add items.
		var nested := {}
		var id := 0
		for item in get_items():
			var item_text: String = item
			var popup: PopupMenu = op
			if split_join in item:
				var parts := (item as String).split(split_join)
				for i in range(len(parts)-1):
					var part := parts[i]
					if not part in nested:
						var new_popup := PopupMenu.new()
						new_popup.min_size.x = 100
						new_popup.id_pressed.connect(_id_pressed.bind(ed, le))
						nested[part] = new_popup
						popup.add_submenu_node_item(part, new_popup)
						popup = new_popup
				item_text = parts[-1]
			popup.add_item(item_text, id)
			id += 1
		
		ep.add_focusable(le)
		ed.add_property_editor(property, ep, false, property.capitalize())
		# Remove existing.
		return true
	return false

func _id_pressed(id: int, ed, le):
	#ep.emit_changed(property, items[id], "", true)
	#ep.update_property()
	ed.target[property] = items[id]
	le.text = items[id]
