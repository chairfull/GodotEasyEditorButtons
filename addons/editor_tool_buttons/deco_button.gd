@tool
extends "decorator.gd"
## Add above method to have them show up in the inspector.
## Add multiple to the same method for them to group horizontally.
## 
## #@button
## func mybutton():
## 		pass

const DecoButton := preload("deco_button.gd")
const TooltipOverride := preload("tooltip_override.gd")

var args := []
var color := Color.WHITE
var label := ""
var tooltip := ""
var kwargs := {}

func _init(args := [], color := Color.WHITE, label := "", kwargs := {}) -> void:
	self.args = args
	self.label = label
	self.color = color
	self.kwargs = kwargs

func show_in_inspector() -> bool:
	return true

func group_in_inspector() -> bool:
	return true

func _parse_begin(ed: EditorInspectorPlugin):
	var group: Array[Decorator] = ed.get_group(self)
	
	# Show a single button.
	if len(group) == 1:
		var btn := _create_button(self)
		
		var mt := get_method_comment()
		if mt:
			btn.tooltip_text += "\n\n" + mt
		
		ed.add_custom_control(btn)
	
	# Show a group in a single row.
	else:
		var hbox := HBoxContainer.new()
		hbox.set_script(TooltipOverride)
		
		var tooltip := []
		tooltip.append("Method: [u][b]%s[/b][/u]" % [method])
		tooltip.append("Line: [u][b]%s[/b][/u]" % [_source_line_meth])
		var mc := get_method_comment()
		if mc:
			tooltip.append("")
			tooltip.append(mc)
		hbox.tooltip_text = "\n".join(tooltip)
		
		if method:
			var lbl := Label.new()
			lbl.text = method.capitalize()
			hbox.add_child(lbl)
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for deco: DecoButton in group:
			var btn := _create_button(deco, false)
			btn.text = (deco.label if deco.label else " ".join(deco.args) if deco.args else "...")
			hbox.add_child(btn)
		ed.add_custom_control(hbox)

func _create_button(deco: DecoButton, show_method_tooltip := true) -> Button:
	var btn: Button
	if deco.label.begins_with("res://"):
		btn = Button.new()
		btn.icon = load(deco.label)
		btn.icon_alignment
		btn.text = deco.method.capitalize()
	else:
		btn = Button.new()
		btn.text = (deco.label if deco.label else deco.method.capitalize())
	
	if "font_size" in deco.kwargs:
		btn.add_theme_font_size_override("font_size", deco.kwargs.font_size)
	
	#for key in deco.kwargs:
		#if key in btn:
			#btn[key] = deco.kwargs[key]
	
	btn.set_script(TooltipOverride)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.self_modulate = deco.color
	btn.pressed.connect(deco.get_method().bindv(deco.args))
	var tooltip := []
	
	if show_method_tooltip and deco.method:
		tooltip.append("Method: [u][b]%s[/b][/u]" % [deco.method])
	
	if deco.args:
		tooltip.append("Arguments: [u][b]%s[/b][/u]" % [", ".join(deco.args)])
	
	if deco._source_line_deco != -1:
		tooltip.append("Line: [u][b]%s[/b][/u]" % [deco._source_line_deco])
	
	if deco.tooltip:
		tooltip.append("")
		tooltip.append(deco.tooltip)
	
	var dt := deco.get_decorator_comment()
	if dt:
		tooltip.append("")
		tooltip.append(dt)
	
	btn.tooltip_text = "\n".join(tooltip)
	return btn
