extends CharacterBody3D
## Saqueador/zumbi simples: vagueia, persegue o jogador de perto e ataca.

const Model = preload("res://scripts/character_model.gd")

var health := 50.0
var speed := 3.0
var dead := false
var player = null
var model
var _atk_cd := 0.0
var _wander_t := 0.0
var _wander_dir := Vector3.ZERO


func _ready() -> void:
    add_to_group("enemies")
    collision_layer = 2
    collision_mask = 1
    floor_snap_length = 0.6
    var cs := CollisionShape3D.new()
    var cap := CapsuleShape3D.new()
    cap.radius = 0.35
    cap.height = 1.8
    cs.shape = cap
    cs.position.y = 0.9
    add_child(cs)
    model = Model.new()
    model.skin = Color(0.55, 0.66, 0.46)
    model.shirt = Color(0.42, 0.14, 0.12)
    model.pants = Color(0.14, 0.12, 0.1)
    model.pack_on = false
    model.zombie = true
    add_child(model)
    model.build()


func _physics_process(delta: float) -> void:
    if dead:
        return
    _atk_cd -= delta
    if not is_on_floor():
        velocity.y -= 24.0 * delta
    var dir := Vector3.ZERO
    var spd := 0.0
    var chasing := false
    if player != null and is_instance_valid(player) and not player.dead:
        var to: Vector3 = player.global_position - global_position
        to.y = 0.0
        var d := to.length()
        if d < 22.0:
            chasing = true
            if d > 1.6:
                dir = to.normalized()
                spd = speed * (1.6 if d < 10.0 else 1.0)
            elif _atk_cd <= 0.0:
                _atk_cd = 1.2
                model.swing()
                player.take_damage(8.0)
    if not chasing:
        _wander_t -= delta
        if _wander_t <= 0.0:
            _wander_t = randf_range(2.0, 5.0)
            if randf() < 0.5:
                _wander_dir = Vector3.ZERO
            else:
                var a := randf() * TAU
                _wander_dir = Vector3(cos(a), 0, sin(a))
        dir = _wander_dir
        spd = speed * 0.4
    velocity.x = dir.x * spd
    velocity.z = dir.z * spd
    move_and_slide()
    if dir.length() > 0.1:
        model.rotation.y = lerp_angle(model.rotation.y, atan2(-dir.x, -dir.z), minf(1.0, 8.0 * delta))
    model.animate(delta, spd / 4.5)


func take_damage(a: float) -> void:
    if dead:
        return
    health -= a
    if health <= 0.0:
        _die()


func _die() -> void:
    dead = true
    remove_from_group("enemies")
    collision_layer = 0
    var tw := create_tween()
    tw.tween_property(model, "rotation:x", -PI * 0.5, 0.4)
    get_tree().create_timer(3.0).timeout.connect(queue_free)
    var m := get_tree().get_first_node_in_group("main")
    if m:
        var r := randf()
        var kind := "scrap"
        if r < 0.35:
            kind = "ammo"
        elif r < 0.6:
            kind = "food"
        elif r < 0.8:
            kind = "water"
        m.call_deferred("spawn_pickup", kind, 4 if kind == "ammo" else 1, global_position + Vector3(0, 0.6, 0))
