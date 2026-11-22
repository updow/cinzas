extends Control
## HUD + controles de toque (multitoque), tudo desenhado por código.

var player
var builder

var _fingers := {}          # índice do dedo -> "stick" | "look" | nome do botão
var _stick_center := Vector2.ZERO
var _stick_pos := Vector2.ZERO
var _msg := ""
var _msg_t := 0.0
var _dead_t := 0.0


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE


func toast(t: String) -> void:
    _msg = t
    _msg_t = 3.0


func _process(delta: float) -> void:
    _msg_t = maxf(0.0, _msg_t - delta)
    if player and player.dead:
        _dead_t += delta
    queue_redraw()


# ---------- toque ----------
func _buttons() -> Dictionary:
    var s := get_viewport_rect().size
    var b := {}
    var driving: bool = player != null and player.vehicle != null
    var a := Vector2(s.x - 100.0, s.y - 110.0)
    b["interact"] = {"p": a + Vector2(10, -115), "r": 46.0, "t": "Sair" if driving else "Ação"}
    b["jump"] = {"p": a + Vector2(-120, -85), "r": 40.0, "t": "Freio" if driving else "Pular"}
    if not driving:
        b["shoot"] = {"p": a, "r": 50.0, "t": "Atirar"}
        b["melee"] = {"p": a + Vector2(-110, 30), "r": 44.0, "t": "Golpe"}
        b["run"] = {"p": a + Vector2(-230, 40), "r": 40.0, "t": "Correr"}
    b["eat"] = {"p": Vector2(s.x - 290, 50), "r": 34.0, "t": "Comer"}
    b["drink"] = {"p": Vector2(s.x - 215, 50), "r": 34.0, "t": "Beber"}
    if not driving:
        b["build"] = {"p": Vector2(s.x - 140, 50), "r": 34.0, "t": "Base"}
        if builder != null and builder.active:
            b["piece"] = {"p": Vector2(s.x - 215, 125), "r": 34.0, "t": "Peça"}
            b["place"] = {"p": Vector2(s.x - 140, 125), "r": 34.0, "t": "Pôr"}
    return b


func _hit_button(p: Vector2) -> String:
    var bs := _buttons()
    for n in bs:
        var b: Dictionary = bs[n]
        if p.distance_to(b["p"]) <= float(b["r"]) + 10.0:
            return n
    return ""


func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        var p: Vector2 = event.position
        var s := get_viewport_rect().size
        if event.pressed:
            if player and player.dead:
                if _dead_t > 1.0:
                    Ctrl.touch_move = Vector2.ZERO
                    Ctrl.touch_held.clear()
                    get_tree().reload_current_scene()
                return
            var b := _hit_button(p)
            if b != "":
                _fingers[event.index] = b
                Ctrl.btn_down(b)
            elif p.x < s.x * 0.45 and p.y > s.y * 0.3 and not _fingers.values().has("stick"):
                _fingers[event.index] = "stick"
                _stick_center = p
                _stick_pos = p
            else:
                _fingers[event.index] = "look"
        else:
            _release(event.index)
    elif event is InputEventScreenDrag:
        var f = _fingers.get(event.index, "")
        if f == "stick":
            _stick_pos = event.position
            var v := ((_stick_pos - _stick_center) / 70.0).limit_length(1.0)
            Ctrl.touch_move = Vector2(v.x, -v.y)
        elif f == "look":
            Ctrl.look += event.relative


func _release(index: int) -> void:
    var f = _fingers.get(index, "")
    if f == "stick":
        Ctrl.touch_move = Vector2.ZERO
    elif f != "" and f != "look":
        Ctrl.btn_up(f)
    _fingers.erase(index)


# ---------- desenho ----------
func _txt(pos: Vector2, text: String, fs := 15, col := Color.WHITE, al := HORIZONTAL_ALIGNMENT_LEFT, w := -1.0) -> void:
    var font := ThemeDB.fallback_font
    draw_string(font, pos + Vector2(1, 1), text, al, w, fs, Color(0, 0, 0, 0.7))
    draw_string(font, pos, text, al, w, fs, col)


func _bar(pos: Vector2, v: float, col: Color, label: String) -> void:
    draw_rect(Rect2(pos, Vector2(210, 18)), Color(0, 0, 0, 0.5))
    draw_rect(Rect2(pos, Vector2(210.0 * clampf(v / 100.0, 0.0, 1.0), 18)), col)
    _txt(pos + Vector2(6, 14), label, 13)


func _draw() -> void:
    if player == null:
        return
    var s := get_viewport_rect().size
    var m := Vector2(16, 16)
    _bar(m, player.health, Color(0.77, 0.27, 0.18), "Vida")
    _bar(m + Vector2(0, 24), player.hunger, Color(0.85, 0.5, 0.17), "Fome")
    _bar(m + Vector2(0, 48), player.thirst, Color(0.29, 0.66, 0.85), "Sede")
    _bar(m + Vector2(0, 72), player.stamina, Color(0.6, 0.75, 0.3), "Estamina")

    var inv_txt := ""
    for k in ["food", "water", "scrap", "wood", "fuel", "ammo"]:
        inv_txt += "%s %d    " % [Ctrl.LABELS[k], player.inv[k]]
    _txt(m + Vector2(0, 112), inv_txt, 14)

    if player.vehicle != null:
        var v = player.vehicle
        _txt(m + Vector2(0, 134), "Veículo: combustível %d%%   %d km/h" % [int(v.fuel), int(v.linear_velocity.length() * 3.6)], 14, Color(1, 0.9, 0.6))
    elif builder != null and builder.active:
        _txt(m + Vector2(0, 134), builder.status_text(), 14, Color(0.6, 1, 0.7))
    else:
        var c := s * 0.5
        draw_line(c + Vector2(-8, 0), c + Vector2(-3, 0), Color(1, 1, 1, 0.7), 2.0)
        draw_line(c + Vector2(3, 0), c + Vector2(8, 0), Color(1, 1, 1, 0.7), 2.0)
        draw_line(c + Vector2(0, -8), c + Vector2(0, -3), Color(1, 1, 1, 0.7), 2.0)
        draw_line(c + Vector2(0, 3), c + Vector2(0, 8), Color(1, 1, 1, 0.7), 2.0)

    if _msg_t > 0.0:
        _txt(Vector2(0, s.y * 0.22), _msg, 18, Color(1, 1, 1, clampf(_msg_t, 0.0, 1.0)), HORIZONTAL_ALIGNMENT_CENTER, s.x)

    # joystick
    var has_stick := _fingers.values().has("stick")
    var base := _stick_center if has_stick else Vector2(150, s.y - 150)
    draw_arc(base, 70.0, 0, TAU, 40, Color(1, 1, 1, 0.35), 3.0)
    var knob := base
    if has_stick:
        knob = base + (_stick_pos - _stick_center).limit_length(70.0)
    draw_circle(knob, 28.0, Color(1, 1, 1, 0.35))

    # botões
    var bs := _buttons()
    for n in bs:
        var b: Dictionary = bs[n]
        var on: bool = Ctrl.held(n)
        draw_circle(b["p"], b["r"], Color(0.9, 0.55, 0.2, 0.6) if on else Color(0, 0, 0, 0.4))
        draw_arc(b["p"], b["r"], 0, TAU, 32, Color(1, 1, 1, 0.6), 2.0)
        _txt(b["p"] + Vector2(-b["r"], 5), b["t"], 14, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, b["r"] * 2.0)

    if player.dead:
        draw_rect(Rect2(Vector2.ZERO, s), Color(0.1, 0.03, 0.02, 0.75))
        _txt(Vector2(0, s.y * 0.45), "Você não sobreviveu", 32, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, s.x)
        _txt(Vector2(0, s.y * 0.45 + 40), "Toque para reiniciar", 18, Color(1, 1, 1, 0.8), HORIZONTAL_ALIGNMENT_CENTER, s.x)
