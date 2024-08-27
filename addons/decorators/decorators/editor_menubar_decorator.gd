@tool
extends "../Decorator.gd"

var path: String
var icon: Variant
var rank: int
var seperator: bool

func _init(path: String = "", icon: Variant = null, rank := 0, seperator := false) -> void:
	self.path = path
	self.icon = icon
	self.rank = rank
	self.seperator = seperator
