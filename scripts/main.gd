extends Node3D
## Monta o mundo de teste inteiro por código.
## Para editar o mapa: mexa em _make_ruins / _make_trees / _random_loot.

const TerrainS = preload("res://scripts/terrain.gd")
const PlayerS = preload("res://scripts/player.gd")
const EnemyS = preload("res://scripts/enemy.gd")
const VehicleS = preload("res://scripts/vehicle.gd")
const PickupS = preload("res://scripts/pickup.gd")
const BuilderS = preload("res://scripts/base_builder.gd")
const UIS = preload("res://scripts/ui.gd")

const WH := 120.0   # metade do mundo (terreno = 2 * 120)
const LOOT := ["food", "food", "water", "water", "scrap", "scrap",
    "wood", "wood", "wood", "fuel", "ammo"]

var terrain
var player
var _enemy_t := 0.0
var _loot_t := 0.0


func _ready() -> void:
    add_to_group("main")
    randomize()
    _make_env()
    terrain = TerrainS.new()
    add_child(terrain)
    terrain.build()
    _make_borders()
    _make_ruins()
    _make_trees()
    for i in 70:
        _random_loot()

    var veh = VehicleS.new()
    veh.position = Vector3(9, 1.5, 6)
    add_child(veh)

    player = PlayerS.new()
    player.position = Vector3(0, 1.0, 0)
    add_child(player)

    var builder = BuilderS.new()
    builder.player = player
    builder.terrain = terrain
    add_child(builder)

    var layer := CanvasLayer.new()
    add_child(layer)
    var ui = UIS.new()
    layer.add_child(ui)
    ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    ui.player = player
    ui.builder = builder
    player.message.connect(ui.toast)
    builder.message.connect(ui.toast)

    for i in 10:
        _spawn_enemy()
    _spawn_enemy_at(Vector3(18, 0, -10))
    _spawn_enemy_at(Vector3(-16, 0, -14))
    ui.toast("Mundo de teste: pegue itens, construa (Base) e dirija (Ação).")


func _process(delta: float) -> void:
    _enemy_t += delta
    if _enemy_t > 8.0:
        _enemy_t = 0.0
        if get_tree().get_nodes_in_group("enemies").size() < 12:
            _spawn_enemy()
    _loot_t += delta
    if _loot_t > 15.0:
        _loot_t = 0.0
        if get_tree().get_nodes_in_group("pickups").size() < 90:
            _random_loot()


func spawn_pickup(kind: String, amount: int, pos: Vector3) -> void:
    var p = PickupS.new()
    p.setup(kind, amount)
    p.position = pos
    add_child(p)


func _random_loot() -> void:
    var x := randf_range(-WH + 6.0, WH - 6.0)
    var z := randf_range(-WH + 6.0, WH - 6.0)
    var kind: String = LOOT[randi() % LOOT.size()]
    spawn_pickup(kind, 6 if kind == "ammo" else 1, Vector3(x, terrain.height_at(x, z) + 0.6, z))


func _spawn_enemy() -> void:
    var pp: Vector3 = player.global_position if player else Vector3.ZERO
    var ang := randf() * TAU
    var dist := randf_range(45.0, 100.0)
    var x := clampf(pp.x + cos(ang) * dist, -WH + 5.0, WH - 5.0)
    var z := clampf(pp.z + sin(ang) * dist, -WH + 5.0, WH - 5.0)
    _spawn_enemy_at(Vector3(x, 0, z))


func _spawn_enemy_at(pos: Vector3) -> void:
    var e = EnemyS.new()
    e.position = Vector3(pos.x, terrain.height_at(pos.x, pos.z) + 1.2, pos.z)
    e.player = player
    add_child(e)


func _make_env() -> void:
    var sm := ProceduralSkyMaterial.new()
    sm.sky_top_color = Color(0.5, 0.46, 0.42)
    sm.sky_horizon_color = Color(0.86, 0.7, 0.5)
    sm.ground_horizon_color = Color(0.7, 0.6, 0.45)
    sm.ground_bottom_color = Color(0.3, 0.25, 0.2)
    var sky := Sky.new()
    sky.sky_material = sm
    var env := Environment.new()
    env.background_mode = Environment.BG_SKY
    env.sky = sky
    env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    env.fog_enabled = true
    env.fog_light_color = Color(0.8, 0.66, 0.48)
    env.fog_density = 0.012
    var we := WorldEnvironment.new()
    we.environment = env
    add_child(we)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-50, -30, 0)
    sun.light_color = Color(1.0, 0.88, 0.7)
    sun.shadow_enabled = true
    sun.directional_shadow_max_distance = 70.0
    add_child(sun)


func _make_borders() -> void:
    var t := 2.0
    var seg_len := WH * 2.0 + 8.0
    _static_box(Vector3(0, 15, -WH), Vector3(seg_len, 40, t), Color(0, 0, 0, 0), 0.0, false)
    _static_box(Vector3(0, 15, WH), Vector3(seg_len, 40, t), Color(0, 0, 0, 0), 0.0, false)
    _static_box(Vector3(-WH, 15, 0), Vector3(t, 40, seg_len), Color(0, 0, 0, 0), 0.0, false)
    _static_box(Vector3(WH, 15, 0), Vector3(t, 40, seg_len), Color(0, 0, 0, 0), 0.0, false)


func _static_box(pos: Vector3, size: Vector3, color: Color, rot_y := 0.0, visible_mesh := true) -> StaticBody3D:
    var b := StaticBody3D.new()
    b.collision_layer = 1
    b.position = pos
    b.rotation.y = rot_y
    var cs := CollisionShape3D.new()
    var sh := BoxShape3D.new()
    sh.size = size
    cs.shape = sh
    b.add_child(cs)
    if visible_mesh:
        var bm := BoxMesh.new()
        bm.size = size
        var mat := StandardMaterial3D.new()
        mat.albedo_color = color
        mat.roughness = 1.0
        bm.material = mat
        var mi := MeshInstance3D.new()
        mi.mesh = bm
        b.add_child(mi)
    add_child(b)
    return b


func _make_ruins() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 42
    var palette := [Color(0.42, 0.38, 0.34), Color(0.5, 0.36, 0.28), Color(0.36, 0.36, 0.34)]
    for i in 22:
        var c := Vector3(rng.randf_range(-105.0, 105.0), 0, rng.randf_range(-105.0, 105.0))
        if Vector2(c.x, c.z).length() < 28.0:
            continue
        var w := rng.randf_range(8.0, 14.0)
        var d := rng.randf_range(8.0, 14.0)
        var col: Color = palette[rng.randi() % palette.size()]
        var defs := [
            [Vector3(0, 0, -d * 0.5), Vector3(w, 1, 0.6)],
            [Vector3(0, 0, d * 0.5), Vector3(w, 1, 0.6)],
            [Vector3(-w * 0.5, 0, 0), Vector3(0.6, 1, d)],
            [Vector3(w * 0.5, 0, 0), Vector3(0.6, 1, d)],
        ]
        for df in defs:
            var sz: Vector3 = df[1]
            sz.y = rng.randf_range(1.0, 1.4) if rng.randf() < 0.3 else rng.randf_range(3.0, 6.0)
            var p: Vector3 = c + df[0]
            p.y = terrain.height_at(p.x, p.z) + sz.y * 0.5 - 0.4
            _static_box(p, sz, col)
        for k in 3:   # loot dentro da ruína
            var lx := c.x + rng.randf_range(-w * 0.35, w * 0.35)
            var lz := c.z + rng.randf_range(-d * 0.35, d * 0.35)
            var kind: String = LOOT[rng.randi() % LOOT.size()]
            spawn_pickup(kind, 6 if kind == "ammo" else 1, Vector3(lx, terrain.height_at(lx, lz) + 0.6, lz))
    # torres: pontos de referência
    for i in 6:
        var p := Vector3(rng.randf_range(-100.0, 100.0), 0, rng.randf_range(-100.0, 100.0))
        if Vector2(p.x, p.z).length() < 35.0:
            continue
        var sz := Vector3(7, rng.randf_range(12.0, 18.0), 7)
        p.y = terrain.height_at(p.x, p.z) + sz.y * 0.5 - 0.5
        _static_box(p, sz, Color(0.34, 0.33, 0.32), rng.randf_range(0.0, 1.5))


func _make_trees() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 7
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.2, 0.15, 0.11)
    mat.roughness = 1.0
    for i in 70:
        var x := rng.randf_range(-WH + 6.0, WH - 6.0)
        var z := rng.randf_range(-WH + 6.0, WH - 6.0)
        if Vector2(x, z).length() < 15.0:
            continue
        var h := rng.randf_range(3.0, 5.0)
        var b := StaticBody3D.new()
        b.collision_layer = 1
        b.position = Vector3(x, terrain.height_at(x, z), z)
        var cs := CollisionShape3D.new()
        var sh := CylinderShape3D.new()
        sh.radius = 0.3
        sh.height = h
        cs.shape = sh
        cs.position.y = h * 0.5
        b.add_child(cs)
        var trunk := CylinderMesh.new()
        trunk.top_radius = 0.08
        trunk.bottom_radius = 0.25
        trunk.height = h
        trunk.material = mat
        var mi := MeshInstance3D.new()
        mi.mesh = trunk
        mi.position.y = h * 0.5
        b.add_child(mi)
        for s in [-1.0, 1.0]:
            var br := CylinderMesh.new()
            br.top_radius = 0.03
            br.bottom_radius = 0.09
            br.height = 1.6
            br.material = mat
            var bi := MeshInstance3D.new()
            bi.mesh = br
            bi.position = Vector3(0.4 * s, h * 0.75, 0)
            bi.rotation_degrees.z = -50.0 * s
            b.add_child(bi)
        add_child(b)
