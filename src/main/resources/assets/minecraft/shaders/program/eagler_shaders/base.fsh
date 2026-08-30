// Eaglercraft Shader Collection - Base Fragment Shader Template
// This is the base template. Specific presets extend this with their own color grading.

#version 120

// ============================================================
// UNIFORMS (Set by ShaderInstance from JSON)
// ============================================================

uniform sampler2D DiffuseSampler;

uniform vec2 InSize;
uniform vec2 OutSize;
uniform vec2 ScreenSize;
uniform float Time;
uniform mat4 ProjMat;

// Quality and feature flags (set per quality level)
uniform int QUALITY_LEVEL;      // 0=LOW, 1=MEDIUM, 2=HIGH
uniform bool ENABLE_FOG;
uniform bool ENABLE_COLOR_GRADING;
uniform bool ENABLE_TONEMAP;
uniform bool ENABLE_VIGNETTE;

// Fog uniforms
uniform vec3 FogColor;
uniform float FogDensity;
uniform float FogStart;
uniform float FogEnd;

// Color grading uniforms
uniform vec3 Lift;
uniform vec3 Gamma;
uniform vec3 Gain;
uniform float Saturation;
uniform float Contrast;
uniform float Brightness;
uniform float Temperature;

// Vignette
uniform float VignetteIntensity;
uniform float VignetteSmoothness;

// Time-based animation
uniform float DayTime;           // 0-1 day cycle

varying vec2 texCoord;
varying vec2 screenUV;

// ============================================================
// SHARED FUNCTIONS (inlined for GLSL ES compatibility)
// ============================================================

const float PI = 3.14159265359;
const float TAU = 6.28318530718;

vec3 srgbToLinear(vec3 c) {
    return pow(max(c, vec3(0.0)), vec3(2.2));
}

vec3 linearToSrgb(vec3 c) {
    return pow(max(c, vec3(0.0)), vec3(1.0 / 2.2));
}

vec3 srgbToLinearFast(vec3 c) {
    return c * c;
}

vec3 linearToSrgbFast(vec3 c) {
    return sqrt(max(c, vec3(0.0)));
}

vec3 adjustSaturation(vec3 color, float saturation) {
    vec3 luminance = vec3(0.2126, 0.7152, 0.0722);
    float l = dot(color, luminance);
    return mix(vec3(l), color, saturation);
}

vec3 adjustContrast(vec3 color, float contrast) {
    return (color - 0.5) * contrast + 0.5;
}

vec3 adjustBrightness(vec3 color, float brightness) {
    return color + brightness;
}

vec3 adjustTemperature(vec3 color, float temp) {
    vec3 warm = vec3(1.0, 0.9, 0.7);
    vec3 cool = vec3(0.7, 0.9, 1.0);
    vec3 tint = mix(cool, warm, temp * 0.5 + 0.5);
    return color * tint;
}

float fogFactorExp(float depth, float density) {
    return 1.0 - exp(-density * depth);
}

float fogFactorExp2(float depth, float density) {
    float f = density * depth;
    return 1.0 - exp(-f * f);
}

float fogFactorLinear(float depth, float start, float end) {
    return smoothstep(start, end, depth);
}

vec3 applyFog(vec3 color, vec3 fogColor, float factor) {
    return mix(color, fogColor, factor);
}

float vignette(vec2 uv, float intensity, float smoothness) {
    vec2 center = vec2(0.5);
    float dist = distance(uv, center) * 2.0;
    return 1.0 - smoothstep(1.0 - smoothness, 1.0, dist) * intensity;
}

vec3 tonemapReinhard(vec3 color) {
    return color / (color + 1.0);
}

vec3 tonemapFilmic(vec3 color) {
    vec3 x = max(vec3(0.0), color - 0.004);
    return (x * (6.2 * x + 0.5)) / (x * (6.2 * x + 1.7) + 0.06);
}

vec3 applyGamma(vec3 color, float gamma) {
    return pow(max(color, vec3(0.0)), vec3(1.0 / gamma));
}

// ============================================================
// PRESET-SPECIFIC COLOR GRADING (OVERRIDE IN PRESET SHADERS)
// ============================================================

// This function is overridden by each preset
vec3 applyPresetColorGrading(vec3 color, vec2 uv, float depth) {
    return color;
}

// ============================================================
// MAIN FRAGMENT SHADER
// ============================================================

void main() {
    // Sample the input color
    vec4 color = texture2D(DiffuseSampler, texCoord);
    vec3 result = color.rgb;
    float alpha = color.a;

    // Convert to linear space for processing
    result = srgbToLinear(result);

    // Apply preset-specific color grading
    if (ENABLE_COLOR_GRADING) {
        result = applyPresetColorGrading(result, texCoord, 0.0);
    }

    // Apply fog if enabled
    if (ENABLE_FOG) {
        // For post-process shaders, we don't have depth, so use screen-space approximation
        // This is a simplified fog - real fog needs depth buffer
        float fogFactor = 0.0;
        // Use screen Y as depth approximation for sky fog
        fogFactor = smoothstep(0.3, 0.8, texCoord.y);
        result = applyFog(result, FogColor, fogFactor * FogDensity);
    }

    // Apply vignette
    if (ENABLE_VIGNETTE) {
        float vig = vignette(screenUV, VignetteIntensity, VignetteSmoothness);
        result *= vig;
    }

    // Tonemapping
    if (ENABLE_TONEMAP) {
        // Use filmic for quality >= MEDIUM, Reinhard for LOW
        if (QUALITY_LEVEL >= 1) {
            result = tonemapFilmic(result);
        } else {
            result = tonemapReinhard(result);
        }
    }

    // Convert back to sRGB
    result = linearToSrgb(result);

    // Apply gamma correction
    result = applyGamma(result, 2.2);

    gl_FragColor = vec4(result, alpha);
}