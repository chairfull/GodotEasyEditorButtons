@tool
extends Node

@export var flag = false

#@dropdown(get_options())
@export var options: String = ""

#@dropdown(get_options_dict())
@export var options_dict: String = ""

#@dropdown(FileScanner.get_ids("res://", ".gd"))
@export var scripts: String = ""

#@dropdown("METHODS")
@export var method: String = ""

#@dropdown("SIGNALS")
@export var signals: String = ""

#@dropdown("PROPERTIES")
@export var property: String = ""

func get_options():
	return ["a", "b", "c", "d"]

func get_options_dict():
	return {
		"item": {
			"child1": {},
			"child2": {
				"innermost_child": {}
			}
		},
		"items2": ""
	}

@export_custom(PROPERTY_HINT_ENUM_SUGGESTION, "a,b,c,d")
var options2: String

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

#@button2d("💩")
## A shitty button.
func ass():
	print("Shitted")

#@button3d("👀")
## Do you see this button?
func myeyes():
	print("I see it...")

#@button([], Color.WHITE, "res://icon.svg", {"expand_icon":true, "custom_minimum_size": Vector2(48.0, 48.0) })
## This button applies all the keys of the final argument as properties to the button.
func teehee():
	print("Tee-hee")
