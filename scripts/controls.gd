extends Node
## Autoload "Ctrl": entrada unificada (teclado + toque).
## Botões: jump run interact melee shoot eat drink build piece place

const LABELS := {
    "food": "Lata", "water": "Água", "scrap": "Sucata",
    "wood": "Madeira", "fuel": "Combustível", "ammo": "Munição",
}
const KEYS := {
    KEY_SPACE: "jump", KEY_SHIFT: "run", KEY_E: "interact", KEY_F: "melee",
    KEY_R: "shoot", KEY_1: "eat", KEY_2: "drink", KEY_B: "build",
    KEY_TAB: "piece", KEY_ENTER: "place",
}

var touch_move := Vector2.ZERO   # x direita, y frente
var look := Vector2.ZERO
var touch_held := {}
var key_held := {}
var _pressed := {}


func _init() -> void:
    process_physics_priority = 1000   # roda por último: limpa os "just pressed"


func _input(event: InputEvent) -> void:
    if event is InputEventKey and not event.echo:
        var n: String = KEYS.get(event.physical_keycode, "")
        if n != "":
            key_held[n] = event.pressed
            if event.pressed:
                _pressed[n] = true
    elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
        look += event.relative


func btn_down(n: String) -> void:
    touch_held[n] = true
    _pressed[n] = true


func btn_up(n: String) -> void:
    touch_held[n] = false


func held(n: String) -> bool:
    return touch_held.get(n, false) or key_held.get(n, false)


func just_pressed(n: String) -> bool:
    return _pressed.get(n, false)


func get_move() -> Vector2:
    if touch_move.length() > 0.1:
        return touch_move
    var v := Vector2.ZERO
    if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
        v.x += 1.0
    if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
        v.x -= 1.0
    if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
        v.y += 1.0
    if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
        v.y -= 1.0
    return v.limit_length(1.0)


func take_look() -> Vector2:
    var l := look
    look = Vector2.ZERO
    return l


func _physics_process(_d: float) -> void:
    _pressed.clear()
