class_name GPULayout

# 128 bytes, std430. Mirrors SceneBuffer in shared_data.gdshaderinc.
# Layout: 28 floats (FractalData params + colors + lightDir + material scalars + RT scalars + background color)
#       + 4 ints  (iterations, use_pbr, 2 pads)
static func pack_scene(s: SceneStateR) -> PackedByteArray:
	var p := s.fractal_data.get_shader_params()
	var ca: Color = s.material.color0
	var cb: Color = s.material.color1
	var out := PackedByteArray()
	out.append_array(PackedFloat32Array([
		p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7],
		ca.r, ca.g, ca.b, 1.0,
		cb.r, cb.g, cb.b, 1.0,
		s.light_dir.x, s.light_dir.y, s.light_dir.z, 0.0,
		s.metallic, s.roughness, s.sdf_scalar, s.lod_scalar,
		s.background_color.r, s.background_color.g, s.background_color.b, s.background_color.a,
	]).to_byte_array())
	out.append_array(PackedInt32Array([
		s.fractal_data.iterations,
		1 if s.use_pbr else 0,
		s.max_steps, 0,
	]).to_byte_array())
	return out

# 32 bytes, std430. Push constants — frame-transient only.
static func pack_frame(jitter: Vector2, history_blend: float,
		res_scale: int, frame_index: int) -> PackedByteArray:
	var out := PackedByteArray()
	out.append_array(PackedFloat32Array([
		jitter.x, jitter.y, history_blend, 0.0,
	]).to_byte_array())
	out.append_array(PackedInt32Array([
		res_scale, frame_index, 0, 0,
	]).to_byte_array())
	return out
