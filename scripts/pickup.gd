extends Area3D
## Item no chão. Coletado automaticamente ao chegar perto (só o jogador).

const INFO := {
    "food": Color(0.85, 0.5, 0.15),
    "water": Color(0.29, 0.66, 0.85),
    "scrap": Color(0.55, 0.55, 0.58),
    "wood": Color(0.5, 0.33, 0.18),
    "fuel": Color(0.8, 0.15, 0.12),
    "ammo": Color(0.9, 0.8, 0.25),
}

var kind := "food"
var amount := 1
var _t := 0.0
var _base_y := 0.0


func setup(k: String, n: int = 1) -> void:
    kind = k
    amount = n


func _ready() -> void:
    add_to_group("pickups")
    collision_layer = 0
    collision_mask = 2
    var cs := CollisionShape3D.new()
    var sp := SphereShape3D.new()
    sp.radius = 1.5
    cs.shape = sp
    add_child(cs)

    var col: Color = INFO[kind]
    var mat := StandardMaterial3D.new()
    mat.albedo_color = col
    mat.emission_enabled = true
    mat.emission = col
    mat.emission_energy_multiplier = 0.35
    var mi := MeshInstance3D.new()
    if kind == "food" or kind == "water":
        var c := CylinderMesh.new()
        c.top_radius = 0.13 if kind == "food" else 0.1
        c.bottom_radius = 0.13 if kind == "food" else 0.1
        c.height = 0.35 if kind == "food" else 0.55
        c.material = mat
        mi.mesh = c
    else:
        var b := BoxMesh.new()
        match kind:
            "wood":
                b.size = Vector3(0.7, 0.14, 0.14)
            "fuel":
                b.size = Vector3(0.35, 0.45, 0.2)
            "ammo":
                b.size = Vector3(0.28, 0.18, 0.2)
            _:
                b.size = Vector3(0.4, 0.25, 0.35)
        b.material = mat
        mi.mesh = b
    add_child(mi)
    _base_y = position.y
    body_entered.connect(_on_body)


func _process(delta: float) -> void:
    _t += delta
    rotation.y += delta * 1.5
    position.y = _base_y + sin(_t * 2.0) * 0.1


func _on_body(b: Node) -> void:
    if b.is_in_group("player"):
        b.add_item(kind, amount)
        queue_free()
