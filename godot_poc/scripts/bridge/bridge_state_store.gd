extends RefCounted
class_name BridgeStateStore

var _last_state: Dictionary = {}
var _last_error: String = ""
var _has_state: bool = false


func apply_response(response: Dictionary) -> void:
    var ok_value: bool = bool(response.get("ok", false))
    var state_value: Variant = response.get("state", null)

    if ok_value and state_value is Dictionary:
        _last_state = state_value.duplicate(true)
        _last_error = ""
        _has_state = true
        return

    if not ok_value:
        _last_error = str(response.get("error", "Unknown error"))


func has_state() -> bool:
    return _has_state


func get_state() -> Dictionary:
    return _last_state.duplicate(true)


func get_last_error() -> String:
    return _last_error
