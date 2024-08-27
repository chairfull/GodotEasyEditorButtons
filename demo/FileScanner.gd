@tool
class_name FileScanner

# Just meant to demonstrate how the @dropdown decorator can access static scripts.
static func get_ids(dir: String, tail: String):
	var ids := []
	_recurs(dir, dir, tail, ids)
	return ids

static func _recurs(root: String, dir: String, tail: String, output: Array):
	for path in DirAccess.get_directories_at(dir):
		var joined := dir.path_join(path)
		_recurs(root, joined, tail, output)
	
	for path in DirAccess.get_files_at(dir):
		if path.ends_with(tail):
			var joined := dir.path_join(path)
			output.append(joined.trim_prefix(root).trim_prefix("/").trim_suffix(tail))
