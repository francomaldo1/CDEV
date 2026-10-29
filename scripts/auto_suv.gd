extends StaticBody3D

@export var custom_material: Material = null

func _ready() -> void:
	if custom_material:
		_apply_material(self)

func _apply_material(node: Node) -> void:
	if node is MeshInstance3D:
		node.material_override = custom_material
	for child in node.get_children():
		_apply_material(child)
