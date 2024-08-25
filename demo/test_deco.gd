@tool
extends Node

@export var flag = false

func _get_editor_buttons():
	return [
		"editor_button",
		#editor_button,
		#editor_button.bind(true),
		#func(): print("Anon Unnamed Button."),
		#func named(): print("Anon Named Button."),
		{ call="editor_button", text="Wot?", type="2D", tint=Color.RED, tooltip="A tip for your tool." }
	]

func editor_button(arg0 := false):
	print("Pressed Editor Button. Arg0: ", arg0)

#@button
func _press_me():
	print("Been pressed...")

#@button
#@button([true], Color.LIGHT_GREEN, "✔️")
#@button([false], Color.LIGHT_PINK, "❌")
func set_flag(f: Variant = null):
	flag = f
	print("Set flag to %s." % [flag])

#@button2D("💩")
## A shitty button.
func ass():
	print("Shitted")

#@button3D("👀")
## Do you see this button?
func myeyes():
	print("I see it...")

#@button([], Color.WHITE, "res://icon.svg", {"expand_icon":true, "custom_minimum_size": Vector2(48.0, 48.0) })
## This button applies all the keys of the final argument as properties to the button.
func teehee():
	print("Tee-hee")
