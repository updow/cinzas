extends Node3D
## Boneco procedural (sem assets). Frente = -Z.
## Defina as cores e chame build(). Use animate() todo frame e swing() ao atacar.

var skin := Color(0.86, 0.68, 0.55)
var shirt := Color(0.28, 0.38, 0.27)
var pants := Color(0.22, 0.2, 0.18)
var pack_on := true
var zombie := false

var _arm_l: Node3D
var _arm_r: Node3D
var _leg_l: Node3D
var _leg_r: Node3D
var _t := 0.0
var _swing := 0.0


func build() -> void:
    _box(self, Vector3(0.5, 0.6, 0.28), Vector3(0, 1.1, 0), shirt)
    var sm := SphereMesh.new()
    sm.radius = 0.17
    sm.height = 0.34
    sm.material = _mat(skin)
    var head := MeshInstance3D.new()
    head.mesh = sm
    head.position = Vector3(0, 1.58, 0)
    add_child(head)
    _box(self, Vector3(0.24, 0.06, 0.05), Vector3(0, 1.6, -0.15), Color(0.08, 0.08, 0.08))
    if pack_on:
        _box(self, Vector3(0.4, 0.5, 0.2), Vector3(0, 1.15, 0.24), Color(0.4, 0.3, 0.18))
    _arm_l = _limb(Vector3(-0.34, 1.38, 0), Vector3(0.14, 0.6, 0.14), shirt)
    _arm_r = _limb(Vector3(0.34, 1.38, 0), Vector3(0.14, 0.6, 0.14), shirt)
    _leg_l = _limb(Vector3(-0.13, 0.8, 0), Vector3(0.18, 0.8, 0.18), pants)
    _leg_r = _limb(Vector3(0.13, 0.8, 0), Vector3(0.18, 0.8, 0.18), pants)
    if not zombie:   # bastão na mão direita
        _box(_arm_r, Vector3(0.08, 0.08, 0.7), Vector3(0, -0.6, -0.3), Color(0.3, 0.2, 0.12))


func animate(delta: float, speed: float) -> void:
    var s := clampf(speed, 0.0, 1.5)
    _t += delta * (5.0 + s * 6.0)
    var a := sin(_t) * 0.7 * minf(s, 1.0)
    _leg_l.rotation.x = a
    _leg_r.rotation.x = -a
    _arm_l.rotation.x = -1.4 if zombie else -a
    if _swing > 0.0:
        _swing -= delta
        var p := 1.0 - clampf(_swing / 0.25, 0.0, 1.0)
        _arm_r.rotation.x = lerpf(-2.4, 0.3, p)
    else:
        _arm_r.rotation.x = -1.4 if zombie else a


func swing() -> void:
    _swing = 0.25


func _mat(c: Color) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = c
    m.roughness = 1.0
    return m


func _box(parent: Node3D, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
    var bm := BoxMesh.new()
    bm.size = size
    bm.material = _mat(color)
    var mi := MeshInstance3D.new()
    mi.mesh = bm
    mi.position = pos
    parent.add_child(mi)
    return mi


func _limb(pivot_pos: Vector3, size: Vector3, color: Color) -> Node3D:
    var p := Node3D.new()
    p.position = pivot_pos
    add_child(p)
    _box(p, size, Vector3(0, -size.y * 0.5, 0), color)
    return p
