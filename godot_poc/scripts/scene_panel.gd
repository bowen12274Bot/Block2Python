extends PanelContainer

@onready var mode_label: Label = $SceneMargin/SceneRoot/SceneMeta/ModeLabel
@onready var node_label: Label = $SceneMargin/SceneRoot/SceneMeta/NodeLabel
@onready var title_label: Label = $SceneMargin/SceneRoot/SceneTitle
@onready var body_text: RichTextLabel = $SceneMargin/SceneRoot/SceneBody


func show_scene(scene_view: Dictionary) -> void:
    mode_label.text = str(scene_view.get("mode_label", "Mode: -"))
    node_label.text = str(scene_view.get("node_label", "Node: -"))
    title_label.text = str(scene_view.get("title", "Scene"))
    body_text.text = str(scene_view.get("body", ""))


func show_placeholder(message: String) -> void:
    show_scene({
        "mode_label": "Mode: -",
        "node_label": "Node: -",
        "title": "Scene",
        "body": message,
    })
