extends RefCounted
class_name QuestMapRouteCatalog

const ROUTE_SEGMENTS := [
	{"id": "route-01", "to_group": "group-02", "start": "Route01Start", "control": "Route01Control", "end": "Route01End"},
	{"id": "route-02", "to_group": "group-03", "start": "Route02Start", "control": "Route02Control", "end": "Route02End"},
	{"id": "route-03", "to_group": "group-04", "start": "Route03Start", "control": "Route03Control", "end": "Route03End"},
	{"id": "route-04", "to_group": "group-05", "start": "Route04Start", "control": "Route04Control", "end": "Route04End"},
]

const ROUTE_STATUS_BRIGHTNESS := {
	"locked": 0.22,
	"available": 0.7,
	"current": 1.0,
	"completed": 0.9,
	"reviewing": 0.82,
}


static func route_segments() -> Array[Dictionary]:
	var segments: Array[Dictionary] = []
	for route_variant in ROUTE_SEGMENTS:
		if route_variant is Dictionary:
			segments.append(route_variant)
	return segments


static func brightness_for_status(status_key: String) -> float:
	return float(ROUTE_STATUS_BRIGHTNESS.get(status_key, 0.28))
