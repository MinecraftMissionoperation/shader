// Eaglercraft Shader Collection - Soft MEDIUM
// Balanced gentle atmosphere with dynamic sky colors

#version 120

uniform sampler2D DiffuseSampler;

uniform vec2 InSize;
uniform vec2 OutSize;
uniform vec2 ScreenSize;
uniform float Time;
uniform mat4 ProjMat;

uniform int QUALITY_LEVEL;
uniform bool ENABLE_FOG;
uniform bool ENABLE_COLOR_GRADING;
uniform bool ENABLE_TONEMAP;
uniform bool ENABLE_VIGNETTE;

uniform vec3 FogColor;
uniform float FogDensity;
uniform float FogStart;
uniform float FogEnd;

uniform vec3 Lift;
uniform vec3 Gamma;
uniform vec3 Gain;
uniform float Saturation;
uniform float Contrast;
uniform float Brightness;
uniform float Temperature;

uniform float VignetteIntensity;
uniform float VignetteSmoothness;

uniform float DayTime;

varying vec2 texCoord;
varying vec2 screenUV;

const float PI = 3.14159265359;
const float TAU = 6.28318530718;

vec3 srgbToLinear(vec3 c) { return pow(max(c, vec3(0.0)), vec3(2.2)); }
vec3 linearToSrgb(vec3 c) { return pow(max(c, vec3(0.0)), vec3(1.0 / 2.2)); }

vec3 adjustSaturation(vec3 color, float saturation) {
    vec3 luminance = vec3(0.2126, 0.7152, 0.0722);
    float l = dot(color, luminance);
    return mix(vec3(l), color, saturation);
}

vec3 adjustContrast(vec3 color, float contrast) { return (color - 0.5) * contrast + 0.5; }
vec3 adjustBrightness(vec3 color, float brightness) { return color + brightness; }
vec3 adjustTemperature(vec3 color, float temp) {
    vec3 warm = vec3(1.0, 0.9, 0.7);
    vec3 cool = vec3(0.7, 0.9, 1.0);
    vec3 tint = mix(cool, warm, temp * 0.5 + 0.5);
    return color * tint;
}

float fogFactorExp(float depth, float density) { return 1.0 - exp(-density * depth); }
float fogFactorExp2(float depth, float density) { float f = density * depth; return 1.0 - exp(-f * f); }
vec3 applyFog(vec3 color, vec3 fogColor, float factor) { return mix(color, fogColor, factor); }

float vignette(vec2 uv, float intensity, float smoothness) {
    vec2 center = vec2(0.5);
    float dist = distance(uv, center) * 2.0;
    return 1.0 - smoothstep(1.0 - smoothness, 1.0, dist) * intensity;
}

vec3 tonemapReinhard(vec3 color) { return color / (color + 1.0); }
vec3 tonemapFilmic(vec3 color) {
    vec3 x = max(vec3(0.0), color - 0.004);
    return (x * (6.2 * x + 0.5)) / (x * (6.2 * x + 1.7) + 0.06);
}
vec3 applyGamma(vec3 color, float gamma) { return pow(max(color, vec3(0.0)), vec3(1.0 / gamma)); }

vec3 getSkyColor(float dayTime) {
    float sunAngle = dayTime * TAU;
    float sunHeight = sin(sunAngle);
    
    vec3 dawnColor = vec3(0.8, 0.7, 0.8);
    vec3 dayColor = vec3(0.65, 0.75, 0.9);
    vec3 nightColor = vec3(0.15, 0.15, 0.25);
    
    if (sunHeight > 0.2) {
        float t = smoothstep(0.2, 1.0, sunHeight);
        return mix(dawnColor, dayColor, t);
    } else if (sunHeight > -0.2) {
        float t = smoothstep(-0.2, 0.2, sunHeight);
        return mix(nightColor, dawnColor, t);
    } else {
        return nightColor;
    }
}

vec3 applyPresetColorGrading(vec3 color, vec2 uv, float depth) {
    float sunHeight = sin(DayTime * TAU);
    
    // Reduced contrast for softness
    color = adjustContrast(color, Contrast);
    
    // Slightly desaturated
    color = adjustSaturation(color, Saturation);
    
    // Gentle warmth
    float dynTemp = mix(0.05, 0.15, smoothstep(-0.2, 0.5, sunHeight));
    color = adjustTemperature(color, dynTemp);
    
    // Shadow lift
    color = adjustBrightness(color, Brightness);
    
    // Sky color influence
    vec3 skyColor = getSkyColor(DayTime);
    color = mix(color, color * skyColor, 0.06);
    
    // Lift shadows
    color = max(color, vec3(0.02));
    
    return color;
}

void main() {
    vec4 color = texture2D(DiffuseSampler, texCoord);
    vec3 result = color.rgb;
    float alpha = color.a;

    result = srgbToLinear(result);

    if (ENABLE_COLOR_GRADING) {
        result = applyPresetColorGrading(result, texCoord, 0.0);
    }

    if (ENABLE_FOG) {
        float fogFactor = fogFactorExp2(texCoord.y * 2.0, FogDensity * 0.4);
        result = applyFog(result, FogColor, fogFactor);
    }

    if (ENABLE_VIGNETTE) {
        float vig = vignette(screenUV, VignetteIntensity, VignetteSmoothness);
        result *= vig;
    }

    if (ENABLE_TONEMAP) {
        result = tonemapFilmic(result);
    }

    result = linearToSrgb(result);
    result = applyGamma(result, 2.2);

    gl_FragColor = vec4(result, alpha);
}