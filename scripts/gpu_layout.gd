class_name GPULayout


static func pack_scene(s: SceneStateR) -> PackedByteArray:
	var p  := s.fractal_data.get_shader_params()
	var ca := s.material.color0
	var cb := s.material.color1
	var out := PackedByteArray()

	out.append_array(PackedFloat32Array([
		p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7],
		ca.r, ca.g, ca.b, 1.0,
		cb.r, cb.g, cb.b, 1.0,
		s.light_dir.x, s.light_dir.y, s.light_dir.z, 0.0,
		s.metallic, s.roughness, s.sdf_scalar, s.lod_scalar,
		s.background_color.r, s.background_color.g, s.background_color.b, s.background_color.a,
		s.exposure, s.iter_norm_a, s.iter_norm_b, 0.0,
	]).to_byte_array())
	out.append_array(PackedInt32Array([
		s.fractal_data.iterations,
		1 if s.use_pbr else 0,
		s.max_steps, 0,
	]).to_byte_array())

	out.append_array(PackedInt32Array([s.color_mode, s.palette_type]).to_byte_array())
	out.append_array(PackedFloat32Array([0.0]).to_byte_array())  
	out.append_array(PackedInt32Array([1 if s.iter_bw_preview else 0]).to_byte_array())

	out.append_array(PackedFloat32Array([
		s.uniform_color.r, s.uniform_color.g, s.uniform_color.b, s.uniform_color.a,
	]).to_byte_array())

	out.append_array(PackedFloat32Array([
		s.trap_position.x, s.trap_position.y, s.trap_position.z, s.trap_size,
	]).to_byte_array())

	out.append_array(PackedInt32Array([s.trap_shape]).to_byte_array())
	out.append_array(PackedFloat32Array([s.trap_norm_a]).to_byte_array())
	out.append_array(PackedInt32Array([1 if s.trap_bw_preview else 0]).to_byte_array())
	out.append_array(PackedFloat32Array([0.0]).to_byte_array())

	out.append_array(PackedFloat32Array([
		s.hsv_cycles, s.hsv_hue_offset,
		s.hsv_blend, s.trap_lp_power,
		s.trap_norm_b, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
	]).to_byte_array())

	return out

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
