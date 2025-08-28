@tool
extends Control
## Add it to a control for that control to have a RichText label.

func _make_custom_tooltip(for_text: String):
	if not for_text:
		return null
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.text = for_text
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.ready.connect(func(): label.custom_minimum_size = Vector2(label.get_content_width(), label.get_content_height()))
	return label
