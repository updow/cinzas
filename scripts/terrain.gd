extends StaticBody3D
## Terreno procedural: malha low-poly + colisão HeightMapShape3D.
## Área plana ao redor de (0,0) para a base inicial.

const N := 97
const SP := 2.5

var _noise := FastNoiseLite.new()
var _tint := FastNoiseLite.new()


func _init() -> void:
    _noise.seed = 1337
    _noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
    _noise.frequency = 0.011
    _noise.fractal_octaves = 3
    _tint.seed = 77
    _tint.frequency = 0.08


func height_at(x: float, z: float) -> float:
    var h := _noise.get_noise_2d(x, z) * 10.0
    return h * smoothstep(14.0, 45.0, Vector2(x, z).length())


func build() -> void:
    collision_layer = 1
    collision_mask = 0
    var half := (N - 1) * 0.5 * SP
    var hs := PackedFloat32Array()
    hs.resize(N * N)
    for zi in N:
        for xi in N:
            hs[zi * N + xi] = height_at(xi * SP - half, zi * SP - half)

    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for zi in N - 1:
        for xi in N - 1:
            var x0 := xi * SP - half
            var z0 := zi * SP - half
            var a := Vector3(x0, hs[zi * N + xi], z0)
            var b := Vector3(x0 + SP, hs[zi * N + xi + 1], z0)
            var c := Vector3(x0, hs[(zi + 1) * N + xi], z0 + SP)
            var d := Vector3(x0 + SP, hs[(zi + 1) * N + xi + 1], z0 + SP)
            var t := _tint.get_noise_2d(x0, z0) * 0.5 + 0.5
            var col := Color(0.52, 0.43, 0.31).lerp(Color(0.36, 0.33, 0.25), t)
            for v in [a, b, d, a, d, c]:
                st.set_color(col)
                st.add_vertex(v)
    st.generate_normals()

    var mat := StandardMaterial3D.new()
    mat.vertex_color_use_as_albedo = true
    mat.roughness = 1.0
    var mi := MeshInstance3D.new()
    mi.mesh = st.commit()
    mi.material_override = mat
    add_child(mi)

    var shape := HeightMapShape3D.new()
    shape.map_width = N
    shape.map_depth = N
    shape.map_data = hs
    var cs := CollisionShape3D.new()
    cs.shape = shape
    cs.scale = Vector3(SP, 1.0, SP)
    add_child(cs)
