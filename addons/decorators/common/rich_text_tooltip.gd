@tool
extends Control
class_name RichTextTooltip
## Add it to a control for that control to have a RichText label.

func _make_custom_tooltip(for_text: String):
	var label := RichTextLabel.new()
	label.custom_minimum_size.x = 300.
	label.bbcode_enabled = true
	label.fit_content = true
	label.text = for_text
	label.set_custom_minimum_size.call_deferred(Vector2(label.get_content_width(), label.get_content_height()))
	return label
