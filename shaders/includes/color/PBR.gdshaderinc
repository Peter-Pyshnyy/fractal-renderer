const float PI = 3.14159265359;

vec3 calcNormal(in vec3 p, in float h)
{
	const vec2 k = vec2(1, -1);
	return normalize(k.xyy * sdf(p + k.xyy * h) +
	                 k.yyx * sdf(p + k.yyx * h) +
	                 k.yxy * sdf(p + k.yxy * h) +
	                 k.xxx * sdf(p + k.xxx * h));
}

float calcAO(vec3 pos, vec3 norm) {
	float occ = 0.0;
	float sca = 1.0;
	for (int i = 0; i < 5; i++) {
		float h = 0.01 + 0.12 * float(i) / 4.0;
		float d = sdf(pos + h * norm);
		occ += (h - d) * sca;
		sca *= 0.95;
	}
	return clamp(1.0 - 3.0 * occ, 0.0, 1.0);
}

float softshadow(in vec3 ro, in vec3 rd, float mint, float maxt, float w)
{
	float res = 1.0;
	float ph  = 1e20;
	float t   = mint;
	for (int i = 0; i < 256 && t < maxt; i++)
	{
		float h = sdf(ro + rd * t);
		if (h < mint * 0.5)
			return 0.0;
		float y = h * h / (2.0 * ph);
		float d = sqrt(h * h - y * y);
		res = min(res, d / (w * max(0.0, t - y)));
		ph  = h;
		t  += h;
	}
	return res;
}

float D_GGX(float NdotH, float roughness) {
	float a  = roughness * roughness;
	float a2 = a * a;
	float d  = NdotH * NdotH * (a2 - 1.0) + 1.0;
	return a2 / (PI * d * d);
}

vec3 F_Schlick(float HdotV, vec3 F0) {
	return F0 + (1.0 - F0) * pow(1.0 - HdotV, 5.0);
}

float G_SchlickGGX(float NdotX, float roughness) {
	float r = roughness + 1.0;
	float k = (r * r) / 8.0;
	return NdotX / (NdotX * (1.0 - k) + k);
}

float G_Smith(float NdotV, float NdotL, float roughness) {
	return G_SchlickGGX(NdotV, roughness) * G_SchlickGGX(NdotL, roughness);
}

vec3 PBR(vec3 N, float N_h, vec3 V, vec3 fragPos, vec3 albedo, float ao, float t) {
	vec3  toLight;
	float attenuation;
	float maxt;
	if (scene.light_type == 0) { // dirLight
		toLight     = normalize(scene.light_dir.xyz);
		attenuation = 1.0;
		maxt        = 5.0;
	} else { // pointLight
		vec3 lightPos = scene.light_type == 1 ? scene.light_dir.xyz : cam.position.xyz;
		vec3  delta   = lightPos - fragPos;
		float dist    = max(length(delta), 0.000001);
		toLight       = delta / dist;
		float r       = scene.light_radius_mult;
		attenuation = pow(max(0.0, 1.0 - (dist / r)), 2.0);
		maxt          = dist; }
	//} else { // egoLight
	//vec3  delta = cam.position.xyz - fragPos;
	//float dist  = max(length(delta), 0.000001);
	//toLight     = delta / dist;
	//float r     = scene.light_radius_mult * t;
	//attenuation = pow(max(0.0, 1.0 - (dist / r)), 2.0) / (dist * dist);
	//maxt        = dist;
//}

	vec3  L    = toLight;
	vec3  H    = normalize(V + L);
	float NdotL = max(dot(N, L), 0.0);
	float NdotV = max(dot(N, V), 0.001);
	float NdotH = max(dot(N, H), 0.0);
	float HdotV = max(dot(H, V), 0.0);

	vec3  F0             = mix(vec3(0.04), albedo, scene.metallic);
	float conv_roughness = max(1e-3, scene.roughness * scene.roughness);

	vec3  bias        = N * N_h * 1.5;
	float adaptiveMint = N_h * 3.0;
	float s = softshadow(fragPos + bias, L, adaptiveMint, maxt, 2.5);
	NdotL *= s;

	float D = D_GGX(NdotH, conv_roughness);
	vec3  F = F_Schlick(HdotV, F0);
	float G = G_Smith(NdotV, NdotL, conv_roughness);

	vec3 specular = (D * F * G) / max(4.0 * NdotV * NdotL, 0.0001);
	vec3 kD       = (1.0 - F) * (1.0 - scene.metallic);
	vec3 diffuse  = kD * albedo / PI;
	vec3 ambient  = vec3(0.03) * albedo * ao;

	vec3 lightColor = scene.light_color.rgb * scene.light_multiplier;
	return (diffuse + specular) * lightColor * attenuation * NdotL + ambient;
}