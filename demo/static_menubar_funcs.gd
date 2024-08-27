@tool
extends RefCounted

#@editor_menubar
static func press_me():
	print("You did it!")

#@editor_menubar("Nested/Button")
static func yee():
	print("Yee-haw!")

#@editor_menubar("/Special/Option")
static func doit():
	print("The @ symbol lets you create a new top level dropdown.")

#@editor_menubar("/Special/", null, 0, true)
#@editor_menubar("/Special/Section 2")
static func div():
	print("This button has a divider above it!")

#@editor_menubar("/Special/Nested/🍎")
static func op():
	print("🍎🍎🍎")

#@editor_menubar("/Special/Nested/🐷")
static func opp():
	print("🐷🐷🐷")
