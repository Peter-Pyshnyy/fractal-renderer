// supports only direction light for RENDERER_FORWARD_PLUS

const float shininess = 32.0;
uniform vec3 globalAmbient = vec3(0.1);
uniform vec3 globalDiffuse = vec3(0.4);
uniform vec3 globalSpecular = vec3(1.0);

vec3 phong(vec3 normal, vec3 viewDir, vec3 lightDir) {
    float diff = max(dot(normal, lightDir), 0.0);
    vec3 reflectDir = reflect(-lightDir, normal);
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), shininess);
    vec3 ambient  = globalAmbient;
    vec3 diffuse  = globalDiffuse  * diff;
    vec3 specular = globalSpecular * spec;
    return ambient + diffuse + specular;
}