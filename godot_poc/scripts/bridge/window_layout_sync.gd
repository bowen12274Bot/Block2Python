extends RefCounted
class_name WindowLayoutSync

static func sync_layout_file(path: String, payload: Dictionary, last_payload: String) -> String:
	var serialized: String = JSON.stringify(payload)
	if serialized == last_payload:
		return last_payload
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return last_payload
	file.store_string(serialized)
	file.flush()
	return serialized
