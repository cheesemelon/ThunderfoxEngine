#version 430

layout(binding = 0) uniform sampler2DMS tex_position;
layout(binding = 1) uniform sampler2DMS tex_albedo;
layout(binding = 2) uniform sampler2DMS tex_normal;

in vec2 UV;

out vec4 FragColor;

uniform mat4 V;
uniform vec2 viewport;
uniform int nSamples;

uniform vec3 lightColor;
uniform vec3 lightDirection_worldspace;

vec3 decodeNormal(vec2 enc){
	float z = dot(enc.xy, enc.xy) * 2.0 - 1.0;
	return vec3(normalize(enc.xy) * sqrt(1.0 - z * z), -z);
}

vec3 calcSample(int n, ivec2 imageCoord){
	vec4 albedo = texelFetch(tex_albedo, imageCoord, n);
	vec3 material_diffuse = albedo.rgb;
	float material_shininess = albedo.a;

	vec3 position = (V * vec4(texelFetch(tex_position, imageCoord, n).xyz, 1.0)).xyz;
	//vec3 L = normalize(vec3(V * vec4(0, 1, 0, 1.0)).xyz - position);
	vec3 L = normalize((V * vec4(lightDirection_worldspace, 0.0)).xyz);
	//vec3 N = texelFetch(tex_normal, imageCoord, n).xyz;
	vec3 N = normalize(decodeNormal(texelFetch(tex_normal, imageCoord, n).xy));
	vec3 E = normalize(vec3(0, 0, 0) - position);
	//vec3 R = reflect(-L, N);
	vec3 R = normalize(2.0 * dot(L, N) * N - L);

	float diffuseIntensity = clamp(dot(N, L), 0.0, 1.0);
	//float specularIntensity = clamp(pow(dot(E, R), material_shininess), 0.0, 1.0);
	float specularIntensity = 0.0;

	return diffuseIntensity * material_diffuse * lightColor
			 + specularIntensity * lightColor;
}

void main(){
	vec3 result = vec3(0.0);
	for(int i=0; i<nSamples; ++i){
		result += calcSample(i, ivec2(UV * viewport));
	}
	result /= 4;
	FragColor = vec4(min(result, 1.0), 1.0);
}