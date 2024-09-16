@FRAMEBUFFER

COUNT(2)
//SIZE(2048)

@VERTEX
layout(location = 0) in vec2 a_position;
void main() { gl_Position = vec4(a_position, 0.0, 1.0); }

@UNIFORMS

uniform float(time) uTime;
uniform vec2(buffer) uSize;
uniform float(0:2:1) uScale;
uniform vec2(-1:1:1,0) uCenter;
uniform int(input:5:1000:20) uIterations;
uniform vec3(color:0.0,0.6,1.0) uColor;
uniform float(checkbox:true) uEnableZMul;
uniform float(checkbox:false) uEnableZInv;
uniform float(checkbox:false) uInvertedShading;
uniform float(0:10:0.5) uInteriorColorFactor;
uniform float(0:10:3.0) uInteriorColorOffset;
uniform float(0:10:0.15) uExteriorColorFactor;
uniform float(0:10:3.0) uExteriorColorOffset;
uniform int(1:10:4) uAA;

@FRAGMENT

layout(location = 0) out vec4 fragColor;
layout(location = 1) out vec4 debug;

vec2 zmul(vec2 a, vec2 b){ // z * z 
	if (uEnableZMul < 0.5) {
		return a * b;
	}
	return mat2(a.x, a.y, -a.y, a.x) * b;
}
vec2 zinv(vec2 z){ // 1 / z
	if (uEnableZInv < 0.5) {
		return z;
	}
	return vec2(z.x, -z.y) / dot(z, z);
}

vec3 julia(vec2 uv) {
	vec2 z = uv * uScale;
	vec2 c = uCenter;
	
	vec3 color = vec3(0);
	
	float r = 0.0;
	float n = 0.0;
	for(int i=0; i<uIterations; ++i) {
		z = zinv(zmul(z,z)) + c;
		r = dot(z,z);
		if (floor(r) > 16.0) {
			break;
		}
		n += 1.0;
	}
	
	if (uInvertedShading > 0.5) {
		r = 0.75 / r; 
	}
	
    float l = n - log(log(r))/log(2);
	
	debug.r = l;
	debug.g = r;
	debug.ba = z;
	
	color = 0.5 + 0.5 * cos( uExteriorColorOffset + l * uExteriorColorFactor + uColor);
	
	if (r < 1.0) {
		color = 0.5 + 0.5 * cos( uInteriorColorOffset + sqrt(z.x * z.y + r * uInteriorColorFactor) * 2.5 + uColor);
	}
	
	return color;
}

void main(void) {
	vec2 g = gl_FragCoord.xy;
	vec2 s = uSize;
	const int AA = uAA;
	const float AAf = float(AA);
	fragColor = vec4(0);
	for(int i=0;i<AA;++i) {
		for(int j=0;j<AA;++j) {
			vec2 o = vec2(i,j) / AAf - 0.5;
			vec2 uv = ((g+o) * 2.0 - s)/s.y;
			fragColor.rgb += julia(uv);
		}
	}
    fragColor.rgb /= AAf * AAf;
	fragColor.a = 1.0;
}