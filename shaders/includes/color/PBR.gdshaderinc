// from https://iquilezles.org/articles/normalsSDF/
vec3 calcNormal( in vec3 p) // for function f(p)
{
    const float h = 0.0001; // replace by an appropriate value
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