extends VehicleBody3D
## Carro simples. Entre/saia com o botão Ação perto dele.
## Ajuste ENGINE_POWER / ENGINE_SIGN abaixo se a direção ou a força ficarem estranhas.

const ENGINE_POWER := 350.0   # força por roda (aumente se estiver lento)
const ENGINE_SIGN := 1.0      # use -1.0 se o carro andar "de ré" ao acelerar
const MAX_SPEED := 24.0       # m/s (~86 km/h)

var driver = null
var fuel := 60.0
var max_fuel := 100.0


func _ready() -> void:
    add_to_group("vehicles")
    mass = 800.0
    can_sleep = false
    collision_layer = 2
    collision_mask = 1
    center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
    center_of_mass = Vector3(0, 0.1, 0)

    var cs := CollisionShape3D.new()
    var sh := BoxShape3D.new()
    sh.size = Vector3(2.0, 0.7, 4.0)
    cs.shape = sh
    cs.position = Vector3(0, 0.65, 0)
    add_child(cs)

    # carroceria (frente = -Z)
    _box(Vector3(2.0, 0.6, 4.0), Vector3(0, 0.65, 0), Color(0.55, 0.28, 0.15))
    _box(Vector3(1.7, 0.6, 1.8), Vector3(0, 1.25, 0.5), Color(0.5, 0.25, 0.14))
    _box(Vector3(1.6, 0.4, 0.08), Vector3(0, 1.3, -0.42), Color(0.1, 0.12, 0.14))
    _box(Vector3(0.4, 0.15, 0.1), Vector3(-0.7, 0.7, -2.0), Color(1.0, 0.9, 0.6))
    _box(Vector3(0.4, 0.15, 0.1), Vector3(0.7, 0.7, -2.0), Color(1.0, 0.9, 0.6))

    _wheel(Vector3(-1.05, 0.45, -1.35), true)
    _wheel(Vector3(1.05, 0.45, -1.35), true)
    _wheel(Vector3(-1.05, 0.45, 1.35), false)
    _wheel(Vector3(1.05, 0.45, 1.35), false)


func set_driver(p) -> void:
    driver = p


func _physics_process(delta: float) -> void:
    var speed := linear_velocity.length()
    if driver == null:
        engine_force = 0.0
        brake = 8.0
        steering = move_toward(steering, 0.0, delta)
        return
    var mv: Vector2 = Ctrl.get_move()
    var thr := mv.y if fuel > 0.0 else 0.0
    engine_force = thr * ENGINE_POWER * ENGINE_SIGN if speed < MAX_SPEED else 0.0
    if Ctrl.held("jump"):
        brake = 40.0
    elif absf(thr) < 0.05:
        brake = 3.0
    else:
        brake = 0.0
    var max_steer := lerpf(0.55, 0.22, clampf(speed / MAX_SPEED, 0.0, 1.0))
    steering = move_toward(steering, -mv.x * max_steer, 2.5 * delta)
    fuel = maxf(0.0, fuel - (0.1 * absf(thr) + 0.01) * delta)
    _roadkill(speed)


func _roadkill(speed: float) -> void:
    if speed < 5.0:
        return
    for e in get_tree().get_nodes_in_group("enemies"):
        if e.global_position.distance_to(global_position) < 2.8:
            e.take_damage(speed * 3.0)


func _box(size: Vector3, pos: Vector3, color: Color) -> void:
    var bm := BoxMesh.new()
    bm.size = size
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.9
    bm.material = mat
    var mi := MeshInstance3D.new()
    mi.mesh = bm
    mi.position = pos
    add_child(mi)


func _wheel(pos: Vector3, steer: bool) -> void:
    var w := VehicleWheel3D.new()
    w.position = pos
    w.use_as_steering = steer
    w.use_as_traction = true
    w.wheel_radius = 0.42
    w.wheel_rest_length = 0.25
    w.suspension_travel = 0.35
    w.suspension_stiffness = 35.0
    w.suspension_max_force = 8000.0
    w.damping_compression = 0.9
    w.damping_relaxation = 1.1
    w.wheel_friction_slip = 3.0
    w.wheel_roll_influence = 0.2
    add_child(w)
    var cm := CylinderMesh.new()
    cm.top_radius = 0.42
    cm.bottom_radius = 0.42
    cm.height = 0.3
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.1, 0.1, 0.1)
    cm.material = mat
    var mi := MeshInstance3D.new()
    mi.mesh = cm
    mi.rotation_degrees.z = 90.0
    w.add_child(mi)
