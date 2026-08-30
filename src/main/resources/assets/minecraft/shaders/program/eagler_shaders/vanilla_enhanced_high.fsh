// Eaglercraft Shader Collection - Vanilla Enhanced HIGH
// Best visuals on capable hardware

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
uniform bool ENABLE_DITHER;

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

// Blue noise dithering for banding reduction
float blueNoise(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

vec3 applyDither(vec3 color) {
    float noise = blueNoise(screenUV * ScreenSize + Time * 100.0) - 0.5;
    return color + noise / 255.0;
}

// Sky color gradient based on time of day
vec3 getSkyColor(float dayTime) {
    float sunAngle = dayTime * TAU;
    float sunHeight = sin(sunAngle);
    
    vec3 dawnColor = vec3(1.0, 0.45, 0.25);
    vec3 dayColor = vec3(0.45, 0.68, 0.95);
    vec3 nightColor = vec3(0.04, 0.04, 0.12);
    
    if (sunHeight > 0.2) {
        float t = smoothstep(0.2, 1.0, sunHeight);
        return mix(dawnColor, dayColor, t);
    } else if (sunHeight > -0.2) {
        float t = smoothstep(-0.2, 0.2, sunHeight);
        return mix(nightColor, dawnColor, t);
    } else {
        float starBrightness = 0.5 + 0.5 * sin(Time * 2.0 + screenUV.x * 100.0) * sin(Time * 1.5 + screenUV.y * 100.0);
        return nightColor + vec3(0.001) * starBrightness;
    }
}

vec3 applyPresetColorGrading(vec3 color, vec2 uv, float depth) {
    // Dynamic sky color influence
    vec3 skyColor = getSkyColor(DayTime);
    color = mix(color, color * skyColor, 0.12);
    
    // Temperature shift based on time (warmer at sunrise/sunset)
    float sunHeight = sin(DayTime * TAU);
    float temp = mix(-0.3, 0.4, smoothstep(-0.3, 0.5, sunHeight));
    color = adjustTemperature(color, temp);
    
    // Saturation with slight desaturation at night
    float sat = mix(0.9, Saturation, smoothstep(-0.1, 0.3, sunHeight));
    color = adjustSaturation(color, sat);
    
    // Contrast
    color = adjustContrast(color, Contrast);
    
    // Brightness
    color = adjustBrightness(color, Brightness);
    
    // Lift/Gamma/Gain
    color = (color - Lift) / (Gain - Lift);
    color = pow(max(color, vec3(0.0)), 1.0 / Gamma);
    
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
        // Exponential squared fog with dynamic color
        float fogFactor = fogFactorExp2(texCoord.y * 2.5, FogDensity * 0.6);
        float sunHeight = sin(DayTime * TAU);
        vec3 dynamicFogColor = mix(FogColor, vec3(0.9, 0.6, 0.3), smoothstep(-0.2, 0.4, sunHeight));
        result = applyFog(result, dynamicFogColor, fogFactor);
    }

    if (ENABLE_VIGNETTE) {
        float vig = vignette(screenUV, VignetteIntensity, VignetteSmoothness);
        result *= vig;
    }

    if (ENABLE_TONEMAP) {
        result = tonemapFilmic(result);
    }

    if (ENABLE_DITHER) {
        result = applyDither(result);
    }

    result = linearToSrgb(result);
    result = applyGamma(result, 2.2);

    gl_FragColor = vec4(result, alpha);
}