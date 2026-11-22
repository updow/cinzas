extends CharacterBody3D
## Jogador: movimento, fome/sede/estamina, inventário, combate e veículos.

signal message(text: String)

const Model = preload("res://scripts/character_model.gd")

var health := 100.0
var hunger := 100.0
var thirst := 100.0
var stamina := 100.0
# Inventário inicial generoso para testar as mecânicas
var inv := {"food": 3, "water": 3, "scrap": 4, "wood": 6, "fuel": 2, "ammo": 15}
var dead := false
var vehicle = null
var cam_yaw := 0.0
var cam_pitch := -0.35
var model
var _rig: Node3D
var _pitch_node: Node3D
var _cam: Camera3D
var _atk_cd := 0.0


func _ready() -> void:
    add_to_group("player")
    collision_layer = 2
    collision_mask = 3
    floor_snap_length = 0.6
    var cs := CollisionShape3D.new()
    var cap := CapsuleShape3D.new()
    cap.radius = 0.35
    cap.height = 1.8
    cs.shape = cap
    cs.position.y = 0.9
    add_child(cs)
    model = Model.new()
    add_child(model)
    model.build()

    _rig = Node3D.new()
    _rig.top_level = true
    add_child(_rig)
    _pitch_node = Node3D.new()
    _rig.add_child(_pitch_node)
    var arm := SpringArm3D.new()
    arm.spring_length = 5.5
    arm.collision_mask = 1
    arm.margin = 0.3
    _pitch_node.add_child(arm)
    _cam = Camera3D.new()
    _cam.fov = 70.0
    _cam.far = 400.0
    arm.add_child(_cam)
    _cam.make_current()


func _process(_delta: float) -> void:
    if dead:
        return
    var l: Vector2 = Ctrl.take_look()
    cam_yaw -= l.x * 0.005
    cam_pitch = clampf(cam_pitch - l.y * 0.004, -1.3, 0.15)
    var target: Node3D = vehicle if vehicle != null else self
    _rig.global_position = target.global_position + Vector3(0, 1.6, 0)
    _rig.rotation.y = cam_yaw
    _pitch_node.rotation.x = cam_pitch


func _physics_process(delta: float) -> void:
    if dead:
        return
    _atk_cd = maxf(0.0, _atk_cd - delta)
    _survival(delta)
    if dead:
        return
    _use_items()
    if vehicle != null:
        global_position = vehicle.global_position
        if Ctrl.just_pressed("interact"):
            _exit_vehicle()
        return
    _move(delta)
    _combat()
    if Ctrl.just_pressed("interact"):
        _try_enter()


# ---------- movimento ----------
func _move(delta: float) -> void:
    var mv: Vector2 = Ctrl.get_move()
    var dir := Vector3(mv.x, 0, -mv.y).rotated(Vector3.UP, cam_yaw)
    var moving := dir.length() > 0.1
    var running: bool = Ctrl.held("run") and moving and stamina > 3.0
    var spd := 8.0 if running else 4.5
    var horiz := Vector3(velocity.x, 0, velocity.z).lerp(dir * spd, minf(1.0, 12.0 * delta))
    velocity.x = horiz.x
    velocity.z = horiz.z
    if is_on_floor():
        if Ctrl.just_pressed("jump"):
            velocity.y = 7.5
    else:
        velocity.y -= 24.0 * delta
    move_and_slide()
    if running:
        stamina = maxf(0.0, stamina - 18.0 * delta)
    else:
        stamina = minf(100.0, stamina + 12.0 * delta)
    if moving:
        model.rotation.y = lerp_angle(model.rotation.y, atan2(-dir.x, -dir.z), minf(1.0, 14.0 * delta))
    model.animate(delta, horiz.length() / 8.0)


# ---------- sobrevivência ----------
func _survival(delta: float) -> void:
    var mult := 1.0
    if vehicle == null and Ctrl.held("run") and Ctrl.get_move().length() > 0.1:
        mult = 2.0
    hunger = maxf(0.0, hunger - 0.25 * mult * delta)
    thirst = maxf(0.0, thirst - 0.40 * mult * delta)
    if hunger <= 0.0 or thirst <= 0.0:
        take_damage(1.5 * delta)
    elif hunger > 40.0 and thirst > 40.0:
        health = minf(100.0, health + 0.8 * delta)
    for f in get_tree().get_nodes_in_group("campfire"):
        if f.global_position.distance_to(global_position) < 6.0:
            health = minf(100.0, health + 3.0 * delta)


func _use_items() -> void:
    if Ctrl.just_pressed("eat"):
        if inv["food"] > 0:
            inv["food"] -= 1
            hunger = minf(100.0, hunger + 30.0)
            message.emit("Comeu uma lata (+30 fome)")
        else:
            message.emit("Sem comida")
    if Ctrl.just_pressed("drink"):
        if inv["water"] > 0:
            inv["water"] -= 1
            thirst = minf(100.0, thirst + 35.0)
            message.emit("Bebeu água (+35 sede)")
        else:
            message.emit("Sem água")


# ---------- inventário ----------
func add_item(kind: String, n: int) -> void:
    inv[kind] += n
    message.emit("+%d %s" % [n, Ctrl.LABELS[kind]])


func can_afford(cost: Dictionary) -> bool:
    for k in cost:
        if inv[k] < cost[k]:
            return false
    return true


func spend(cost: Dictionary) -> bool:
    if not can_afford(cost):
        return false
    for k in cost:
        inv[k] -= cost[k]
    return true


# ---------- combate ----------
func take_damage(a: float) -> void:
    if dead:
        return
    health -= a
    if health <= 0.0:
        dead = true
        health = 0.0
        if vehicle != null:
            vehicle.set_driver(null)
        message.emit("Você morreu")


func _combat() -> void:
    if _atk_cd > 0.0:
        return
    var fwd := Vector3(-sin(cam_yaw), 0, -cos(cam_yaw))
    if Ctrl.just_pressed("melee"):
        _atk_cd = 0.5
        model.rotation.y = atan2(-fwd.x, -fwd.z)
        model.swing()
        for e in get_tree().get_nodes_in_group("enemies"):
            var to: Vector3 = e.global_position - global_position
            to.y = 0.0
            if to.length() < 2.3 and to.normalized().dot(fwd) > 0.3:
                e.take_damage(28.0)
    elif Ctrl.just_pressed("shoot"):
        _atk_cd = 0.3
        if inv["ammo"] <= 0:
            message.emit("Sem munição")
            return
        inv["ammo"] -= 1
        model.rotation.y = atan2(-fwd.x, -fwd.z)
        _fire()


func _fire() -> void:
    var from := _cam.global_position
    var to := from + (-_cam.global_transform.basis.z) * 70.0
    var q := PhysicsRayQueryParameters3D.create(from, to, 3, [get_rid()])
    var hit := get_world_3d().direct_space_state.intersect_ray(q)
    var end := to
    if not hit.is_empty():
        end = hit.position
        var c = hit.collider
        if c != null and c.has_method("take_damage"):
            c.take_damage(35.0)
    _tracer(global_position + Vector3(0, 1.3, 0), end)


func _tracer(a: Vector3, b: Vector3) -> void:
    var seg_len := a.distance_to(b)
    if seg_len < 0.2:
        return
    var bm := BoxMesh.new()
    bm.size = Vector3(0.03, 0.03, seg_len)
    var mat := StandardMaterial3D.new()
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.albedo_color = Color(1.0, 0.9, 0.5)
    bm.material = mat
    var mi := MeshInstance3D.new()
    mi.mesh = bm
    get_tree().current_scene.add_child(mi)
    mi.look_at_from_position((a + b) * 0.5, b, Vector3.UP)
    get_tree().create_timer(0.06).timeout.connect(mi.queue_free)


# ---------- veículo ----------
func _try_enter() -> void:
    var best = null
    var bd := 5.0
    for v in get_tree().get_nodes_in_group("vehicles"):
        var d := global_position.distance_to(v.global_position)
        if d < bd:
            bd = d
            best = v
    if best == null:
        return
    vehicle = best
    vehicle.set_driver(self)
    var added := 0
    while inv["fuel"] > 0 and vehicle.fuel <= vehicle.max_fuel - 25.0:
        inv["fuel"] -= 1
        vehicle.fuel += 25.0
        added += 1
    collision_layer = 0
    collision_mask = 0
    velocity = Vector3.ZERO
    model.visible = false
    if added > 0:
        message.emit("Abastecido com %d galão(ões). Ação para sair." % added)
    else:
        message.emit("No veículo. Ação para sair.")


func _exit_vehicle() -> void:
    var v = vehicle
    v.set_driver(null)
    vehicle = null
    global_position = v.global_position + v.global_transform.basis.x * 2.8 + Vector3(0, 1.5, 0)
    velocity = Vector3.ZERO
    collision_layer = 2
    collision_mask = 3
    model.visible = true
