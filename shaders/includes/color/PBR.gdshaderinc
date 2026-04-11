const float PI = 3.14159265359;
const float u_metallic = 0.75;
const float u_roughness = 0.5;
const vec3 u_lightPos = vec3(1.0, 1.0, 1.0);

// from https://iquilezles.org/articles/normalsSDF/
vec3 calcNormal( in vec3 p) // for function f(p)
{
    const float h = 0.000001; // replace by an appropriate value
    const vec2 k = vec2(1,-1);
    return normalize( k.xyy*sdf( p + k.xyy*h ) + 
                      k.yyx*sdf( p + k.yyx*h ) + 
                      k.yxy*sdf( p + k.yxy*h ) + 
                      k.xxx*sdf( p + k.xxx*h ) );
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

vec3 PBR(vec3 N, vec3 V, vec3 fragPos, vec3 albedo, float ao) {
    vec3 L = normalize(u_lightPos - fragPos);
    vec3 H = normalize(V + L);

    float NdotL = max(dot(N, L), 0.0);
    float NdotV = max(dot(N, V), 0.001);
    float NdotH = max(dot(N, H), 0.0);
    float HdotV = max(dot(H, V), 0.0);

    vec3 F0 = mix(vec3(0.04), albedo, u_metallic);

    // Cook-Torrance specular
    float D = D_GGX(NdotH, u_roughness);
    vec3  F = F_Schlick(HdotV, F0);
    float G = G_Smith(NdotV, NdotL, u_roughness);

    vec3 specular = (D * F * G) / max(4.0 * NdotV * NdotL, 0.001);

    vec3 kD = (1.0 - F) * (1.0 - u_metallic);
    vec3 diffuse = kD * albedo / PI;

    vec3 ambient = vec3(0.03) * albedo * ao;

    return (diffuse + specular) * NdotL + ambient;
}