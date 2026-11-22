extends Node3D
## Sistema de bases: alterna modo construção, mostra "fantasma" e coloca peças
## alinhadas a uma grade de 4 m, gastando materiais do inventário.

signal message(text: String)

const PIECES := [
    {"name": "Piso", "size": Vector3(4, 0.3, 4), "cost": {"wood": 2}},
    {"name": "Parede", "size": Vector3(4, 3, 0.3), "cost": {"wood": 2, "scrap": 1}},
    {"name": "Fogueira", "size": Vector3(0.9, 0.4, 0.9), "cost": {"wood": 1}},
]
const COLORS := [Color(0.38, 0.29, 0.2), Color(0.45, 0.4, 0.36), Color(0.18, 0.14, 0.12)]

var player
var terrain
var active := false
var idx := 0
var _ghost: MeshInstance3D
var _placed := {}


func _ready() -> void:
    _ghost = MeshInstance3D.new()
    _ghost.visible = false
    add_child(_ghost)
    _refresh_ghost()


func status_text() -> String:
    var c: Dictionary = PIECES[idx]["cost"]
    var parts := PackedStringArray()
    for k in c:
        parts.append("%s %d" % [Ctrl.LABELS[k], c[k]])
    return "Construir: %s (%s)" % [PIECES[idx]["name"], ", ".join(parts)]


func _physics_process(_d: float) -> void:
    if player == null or player.dead:
        return
    if player.vehicle != null:
        active = false
        _ghost.visible = false
        return
    if Ctrl.just_pressed("build"):
        active = not active
        _ghost.visible = active
        message.emit("Modo construção " + ("ligado" if active else "desligado"))
    if not active:
        return
    if Ctrl.just_pressed("piece"):
        idx = (idx + 1) % PIECES.size()
        _refresh_ghost()
    if Ctrl.just_pressed("place"):
        _place()


func _process(_d: float) -> void:
    if not active or player == null:
        return
    var t := _target()
    _ghost.position = t.pos
    _ghost.rotation.y = t.rot
    var ok: bool = player.can_afford(PIECES[idx]["cost"])
    var m: StandardMaterial3D = _ghost.mesh.material
    m.albedo_color = Color(0.3, 1.0, 0.4, 0.45) if ok else Color(1.0, 0.3, 0.3, 0.45)


func _refresh_ghost() -> void:
    var bm := BoxMesh.new()
    bm.size = PIECES[idx]["size"]
    var m := StandardMaterial3D.new()
    m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    bm.material = m
    _ghost.mesh = bm


func _target() -> Dictionary:
    var yaw: float = player.cam_yaw
    var fwd := Vector3(-sin(yaw), 0.0, -cos(yaw))
    var p: Vector3 = player.global_position + fwd * 4.5
    var sz: Vector3 = PIECES[idx]["size"]
    var rot := 0.0
    match idx:
        0:
            p.x = round(p.x / 4.0) * 4.0
            p.z = round(p.z / 4.0) * 4.0
        1:
            if absf(fwd.x) > absf(fwd.z):
                rot = PI * 0.5
                p.x = round((p.x - 2.0) / 4.0) * 4.0 + 2.0
                p.z = round(p.z / 4.0) * 4.0
            else:
                p.x = round(p.x / 4.0) * 4.0
                p.z = round((p.z - 2.0) / 4.0) * 4.0 + 2.0
        _:
            p.x = round(p.x)
            p.z = round(p.z)
    p.y = terrain.height_at(p.x, p.z) + sz.y * 0.5
    return {"pos": p, "rot": rot}


func _place() -> void:
    var t := _target()
    var key := "%d:%d:%d:%d" % [idx, int(round(t.pos.x * 2.0)), int(round(t.pos.z * 2.0)), int(round(t.rot * 10.0))]
    if _placed.has(key):
        message.emit("Já existe uma peça aqui")
        return
    var cost: Dictionary = PIECES[idx]["cost"]
    if not player.spend(cost):
        message.emit("Faltam materiais")
        return
    _placed[key] = true
    var sz: Vector3 = PIECES[idx]["size"]
    var body := StaticBody3D.new()
    body.collision_layer = 1
    body.position = t.pos
    body.rotation.y = t.rot
    var cs := CollisionShape3D.new()
    var bs := BoxShape3D.new()
    bs.size = sz
    cs.shape = bs
    body.add_child(cs)
    var bm := BoxMesh.new()
    bm.size = sz
    var mat := StandardMaterial3D.new()
    mat.albedo_color = COLORS[idx]
    mat.roughness = 1.0
    bm.material = mat
    var mi := MeshInstance3D.new()
    mi.mesh = bm
    body.add_child(mi)
    if idx == 2:
        body.add_to_group("campfire")
        var fm := StandardMaterial3D.new()
        fm.albedo_color = Color(1.0, 0.55, 0.15)
        fm.emission_enabled = true
        fm.emission = Color(1.0, 0.5, 0.1)
        var fb := BoxMesh.new()
        fb.size = Vector3(0.35, 0.5, 0.35)
        fb.material = fm
        var fi := MeshInstance3D.new()
        fi.mesh = fb
        fi.position.y = 0.4
        body.add_child(fi)
        var light := OmniLight3D.new()
        light.light_color = Color(1.0, 0.6, 0.25)
        light.omni_range = 9.0
        light.position.y = 1.0
        body.add_child(light)
    add_child(body)
    message.emit("%s construída" % PIECES[idx]["name"])
