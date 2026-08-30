// Eaglercraft Shader Collection - Shared GLSL Utilities
// This file contains common functions used across all shader presets

// ============================================================
// CONSTANTS
// ============================================================

const float PI = 3.14159265359;
const float TAU = 6.28318530718;
const float DEG2RAD = PI / 180.0;
const float RAD2DEG = 180.0 / PI;

// ============================================================
// COLOR SPACE CONVERSIONS
// ============================================================

// sRGB to linear
vec3 srgbToLinear(vec3 c) {
    return pow(max(c, vec3(0.0)), vec3(2.2));
}

// Linear to sRGB
vec3 linearToSrgb(vec3 c) {
    return pow(max(c, vec3(0.0)), vec3(1.0 / 2.2));
}

// Approximate sRGB to linear (faster)
vec3 srgbToLinearFast(vec3 c) {
    return c * c;
}

// Approximate linear to sRGB (faster)
vec3 linearToSrgbFast(vec3 c) {
    return sqrt(max(c, vec3(0.0)));
}

// ============================================================
// COLOR GRADING UTILITIES
// ============================================================

// Lift, Gamma, Gain (3-way color correction)
vec3 liftGammaGain(vec3 color, vec3 lift, vec3 gamma, vec3 gain) {
    color = max(color, vec3(0.0));
    color = (color - lift) / (gain - lift);
    color = pow(max(color, vec3(0.0)), 1.0 / gamma);
    return color;
}

// Saturation adjustment
vec3 adjustSaturation(vec3 color, float saturation) {
    vec3 luminance = vec3(0.2126, 0.7152, 0.0722);
    float l = dot(color, luminance);
    return mix(vec3(l), color, saturation);
}

// Hue shift (approximate, fast)
vec3 shiftHue(vec3 color, float hueShift) {
    // Simple hue rotation in YUV space
    float cosA = cos(hueShift);
    float sinA = sin(hueShift);
    mat3 hueRotate = mat3(
        0.299 + 0.701 * cosA + 0.168 * sinA,
        0.587 - 0.587 * cosA - 0.330 * sinA,
        0.114 - 0.114 * cosA + 0.497 * sinA,
        0.299 - 0.299 * cosA - 0.328 * sinA,
        0.587 + 0.413 * cosA + 0.035 * sinA,
        0.114 - 0.114 * cosA + 0.292 * sinA,
        0.299 - 0.300 * cosA + 1.250 * sinA,
        0.587 - 0.588 * cosA - 1.050 * sinA,
        0.114 + 0.886 * cosA - 0.203 * sinA
    );
    return hueRotate * color;
}

// Contrast adjustment
vec3 adjustContrast(vec3 color, float contrast) {
    return (color - 0.5) * contrast + 0.5;
}

// Brightness adjustment
vec3 adjustBrightness(vec3 color, float brightness) {
    return color + brightness;
}

// Color temperature (warm/cool)
vec3 adjustTemperature(vec3 color, float temp) {
    // temp: -1.0 (cool) to 1.0 (warm)
    vec3 warm = vec3(1.0, 0.9, 0.7);
    vec3 cool = vec3(0.7, 0.9, 1.0);
    vec3 tint = mix(cool, warm, temp * 0.5 + 0.5);
    return color * tint;
}

// ============================================================
// FOG UTILITIES
// ============================================================

// Exponential fog factor
float fogFactorExp(float depth, float density) {
    return 1.0 - exp(-density * depth);
}

// Exponential squared fog factor
float fogFactorExp2(float depth, float density) {
    float f = density * depth;
    return 1.0 - exp(-f * f);
}

// Linear fog factor
float fogFactorLinear(float depth, float start, float end) {
    return smoothstep(start, end, depth);
}

// Apply fog to color
vec3 applyFog(vec3 color, vec3 fogColor, float factor) {
    return mix(color, fogColor, factor);
}

// ============================================================
// LIGHTING UTILITIES
// ============================================================

// Simple sunlight direction calculation
vec3 getSunDirection(float timeOfDay) {
    float angle = timeOfDay * TAU;
    return normalize(vec3(sin(angle), cos(angle * 0.5), cos(angle)));
}

// Ambient light calculation
vec3 getAmbientLight(vec3 normal, vec3 ambientColor, vec3 skyColor, vec3 groundColor) {
    float skyFactor = normal.y * 0.5 + 0.5;
    return mix(groundColor, skyColor, skyFactor) * ambientColor;
}

// ============================================================
// NOISE UTILITIES (Cheap, for LOW quality)
// ============================================================

// Simple hash function
float hash(float x) {
    return fract(sin(x * 12.9898) * 43758.5453);
}

float hash2(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float hash3(vec3 p) {
    return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

// Value noise (cheap)
float valueNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f); // smoothstep
    
    float a = hash2(i + vec2(0.0, 0.0));
    float b = hash2(i + vec2(1.0, 0.0));
    float c = hash2(i + vec2(0.0, 1.0));
    float d = hash2(i + vec2(1.0, 1.0));
    
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// ============================================================
// SCREEN-SPACE UTILITIES
// ============================================================

// Reconstruct view-space position from depth
vec3 reconstructPosition(vec2 uv, float depth, mat4 invProjMat) {
    vec4 clipPos = vec4(uv * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
    vec4 viewPos = invProjMat * clipPos;
    return viewPos.xyz / viewPos.w;
}

// Get depth from depth texture
float getDepth(vec2 uv, sampler2D depthTex) {
    return texture2D(depthTex, uv).r;
}

// ============================================================
// TONEMAPPING
// ============================================================

// Reinhard tonemapping
vec3 tonemapReinhard(vec3 color) {
    return color / (color + 1.0);
}

// ACES filmic tonemapping (approximate)
vec3 tonemapAces(vec3 color) {
    color *= 0.6;
    const mat3 acesIn = mat3(
        0.59719, 0.35458, 0.04823,
        0.07600, 0.90834, 0.01566,
        0.02840, 0.13383, 0.83777
    );
    const mat3 acesOut = mat3(
        1.60475, -0.53108, -0.07367,
        -0.10208, 1.10813, -0.00605,
        -0.00327, -0.07276, 1.07602
    );
    color = acesIn * color;
    color = color * (color + 0.0245786) / (color * (0.983729 * color + 0.4329510) + 0.238081);
    return acesOut * color;
}

// Simple filmic tonemap (cheaper)
vec3 tonemapFilmic(vec3 color) {
    vec3 x = max(vec3(0.0), color - 0.004);
    return (x * (6.2 * x + 0.5)) / (x * (6.2 * x + 1.7) + 0.06);
}

// ============================================================
// VIGNETTE
// ============================================================

// Radial vignette
float vignette(vec2 uv, float intensity, float smoothness) {
    vec2 center = vec2(0.5);
    float dist = distance(uv, center) * 2.0;
    return 1.0 - smoothstep(1.0 - smoothness, 1.0, dist) * intensity;
}

// ============================================================
// GAMMA CORRECTION
// ============================================================

// Apply gamma correction
vec3 applyGamma(vec3 color, float gamma) {
    return pow(max(color, vec3(0.0)), vec3(1.0 / gamma));
}

// ============================================================
// QUALITY DEFINES (Set via shader program JSON uniforms)
// ============================================================

// These are set as uniforms from the Java side:
// uniform int QUALITY_LEVEL; // 0=LOW, 1=MEDIUM, 2=HIGH
// uniform bool ENABLE_FOG;
// uniform bool ENABLE_COLOR_GRADING;
// uniform bool ENABLE_TONEMAP;
// uniform bool ENABLE_VIGNETTE;
// uniform bool ENABLE_NOISE;

// Helper macros for conditional compilation
// Note: GLSL ES doesn't support #ifdef on uniforms, so use runtime branching
// But we can use preprocessor defines at compile time via the JSON