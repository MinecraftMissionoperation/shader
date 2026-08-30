# Eaglercraft Shader Collection

A lightweight, visually distinctive shader collection for Eaglercraft with **light and dark presets** optimised for **low-end WebGL devices** (integrated GPUs, older Chromebooks, weak laptops).

## Features

- **6 Presets**: Vanilla Enhanced, Bright, Soft, Nightfall, Noir, Abyss
- **3 Quality Levels**: LOW (aggressive optimisation), MEDIUM (balanced), HIGH (best visuals)
- **One-step integration**: `EaglercraftShaderIntegration.install(renderer)`
- **Safe fallbacks**: Failed shaders automatically fall back to vanilla rendering
- **Minimal overhead**: Vanilla Enhanced LOW targets vanilla FPS
- **No expensive effects**: No ray tracing, volumetric lighting, SSR, or heavy blur chains

## Presets

### Light Presets
| Preset | Description |
|--------|-------------|
| **Vanilla Enhanced** | Default. Improved colour balance, better sunlight, lightweight fog, subtle water enhancement |
| **Bright** | Brighter lighting, clearer atmosphere, more vibrant colours |
| **Soft** | Gentle colour transitions, reduced harsh lighting, subtle atmosphere |

### Dark Presets
| Preset | Description |
|--------|-------------|
| **Nightfall** | Darker ambient, increased contrast, atmospheric fog, nighttime mood |
| **Noir** | High contrast, dark appearance, reduced saturation, strong visual identity |
| **Abyss** | Deep shadows, cool/dark colour grading, atmospheric darkness |

## Quality Levels

| Level | Description | Target |
|-------|-------------|--------|
| **LOW** | Disables tonemap, vignette, dithering. Fast sRGB conversion. Minimal fog. | Weak integrated GPUs, older devices |
| **MEDIUM** | Enables filmic tonemap, vignette, dynamic sky colours, better fog. | Balanced visuals/FPS |
| **HIGH** | Adds dithering, moon glow (Nightfall), dynamic temperature, exponential² fog. | Capable hardware |

## Quick Start

### 1. Add the Module

**Gradle (build.gradle.kts):**
```kotlin
repositories {
    mavenCentral()
    maven { url = uri("https://eaglercraft-teavm-fork.github.io/maven/") }
}

dependencies {
    implementation("com.eaglercraft.shaders:eagler-shaders:1.0.0")
}
```

**Or copy the JAR** to your `mods` folder / classpath.

### 2. Initialize

In your client initialization code (e.g., your main mod class or client setup):

```java
import com.eaglercraft.shaders.EaglercraftShaderIntegration;
import net.minecraft.client.renderer.GameRenderer;

// Call once during client startup, after GameRenderer is created
EaglercraftShaderIntegration.install(gameRenderer);
```

That's it! The default preset (Vanilla Enhanced LOW) is now active.

### 3. Use the API

```java
import com.eaglercraft.shaders.*;

// Switch presets
ShaderCollection.enable("nightfall");
ShaderCollection.enable("bright");
ShaderCollection.enable(ShaderPreset.NOIR);

// Change quality (requires re-enabling preset)
ShaderCollection.setQuality(ShaderQuality.MEDIUM);
ShaderCollection.setQuality(ShaderQuality.HIGH);

// Toggle on/off
ShaderCollection.toggleShaders();
ShaderCollection.disableShaders();

// Query state
ShaderPreset current = ShaderCollection.getCurrentPreset();
ShaderQuality quality = ShaderCollection.getCurrentQuality();
boolean active = ShaderCollection.areShadersActive();
```

## Integration Details

### For Forge Mods
The `ShaderCollectionMod` class auto-initialises on `FMLClientSetupEvent`. Just add the mod to your project.

### For Manual Integration
```java
// In your client code where you have access to GameRenderer
GameRenderer renderer = Minecraft.getInstance().gameRenderer;
EaglercraftShaderIntegration.install(renderer);

// Later, when window resizes:
EaglercraftShaderIntegration.onFramebufferResize(width, height);

// On resource reload:
EaglercraftShaderIntegration.onResourceReload(resourceManager);

// On shutdown:
EaglercraftShaderIntegration.onShutdown();
```

### Hooking into GameRenderer
If you need to replace Eaglercraft's vanilla shader rendering, modify `GameRenderer.updateCameraAndRender`:

```java
// In GameRenderer.updateCameraAndRender, replace the shader rendering section:
if (GLX.usePostProcess) {
    mc.worldRenderer.renderEntityOutlineFramebuffer();
    // Replace vanilla shader rendering with:
    EaglercraftShaderIntegration.renderShaders(partialTicks, this.useShader);
    mc.getFramebuffer().bindFramebuffer(true);
}
```

## Performance Notes

### What LOW Mode Disables
- Tonemapping (Reinhard only if enabled)
- Vignette effect
- Blue noise dithering
- Dynamic sky colour calculations
- Exponential² fog (uses simple linear)
- Temperature shifts based on time of day
- Full sRGB/linear conversion (uses fast approximation)

### Estimated Overhead (vs Vanilla)
| Preset | Quality | Overhead |
|--------|---------|----------|
| Vanilla Enhanced | LOW | ~1-2% |
| Vanilla Enhanced | MEDIUM | ~3-5% |
| Vanilla Enhanced | HIGH | ~5-8% |
| Nightfall | LOW | ~2-3% |
| Nightfall | MEDIUM | ~4-6% |
| Nightfall | HIGH | ~6-10% |
| Noir | LOW | ~1-2% |
| Abyss | LOW | ~2-4% |

### Optimisation Tips
- Use **LOW** quality on integrated graphics / Chromebooks
- **Disable fog** (`ENABLE_FOG=false` in JSON) for maximum FPS
- **Disable vignette** for slight FPS gain
- Avoid switching presets every frame

## Shader Architecture

```
ShaderCollection (core)
    ↓
EaglercraftShaderIntegration (adapter)
    ↓
GameRenderer (Eaglercraft)
```

### File Structure
```
src/main/resources/assets/minecraft/shaders/program/eagler_shaders/
├── base.vsh                    # Shared vertex shader
├── base.fsh                    # Base fragment template
├── util.glsl                   # Shared GLSL functions
├── vanilla_enhanced_low.fsh
├── vanilla_enhanced_low.json
├── vanilla_enhanced_medium.fsh
├── vanilla_enhanced_medium.json
├── vanilla_enhanced_high.fsh
├── vanilla_enhanced_high.json
├── bright_low.fsh / .json
├── soft_low.fsh / .json
├── nightfall_low.fsh / .json
├── nightfall_medium.fsh / .json
├── nightfall_high.fsh / .json
├── noir_low.fsh / .json
└── abyss_low.fsh / .json
```

## Building

```bash
./gradlew build
# Output: build/libs/eagler-shaders-1.0.0.jar
```

## Requirements

- Eaglercraft 1.16.5+ (26.2+ workspace)
- Java 11+
- Forge 36+
- WebGL 1.0+ / OpenGL ES 2.0+

## Known Limitations

1. **No depth buffer access** in post-process shaders - fog uses screen-space Y approximation
2. **No motion vectors** - temporal effects not possible
3. **WebGL 1 constraints** - limited uniform counts, no compute shaders
4. **DayTime uniform** must be updated from Java side for time-based effects
5. **Entity outline framebuffer** not integrated - outlines render on top of shaders
6. **No multi-pass** - single post-process pass only

## License

Apache-2.0 License - See [LICENSE](LICENSE) for details.

## Credits

- Eaglercraft team for the shader infrastructure
- lax1dude for Eaglercraft
- Mojang for Minecraft