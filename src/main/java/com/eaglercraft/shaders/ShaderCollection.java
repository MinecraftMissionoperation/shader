package com.eaglercraft.shaders;

import net.lax1dude.eaglercraft.opengl.EaglercraftGPU;
import net.minecraft.client.Minecraft;
import net.minecraft.client.renderer.GameRenderer;
import net.minecraft.client.shader.ShaderGroup;
import net.minecraft.resources.IResourceManager;
import net.minecraft.util.ResourceLocation;
import net.minecraftforge.api.distmarker.Dist;
import net.minecraftforge.api.distmarker.OnlyIn;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.function.Supplier;

/**
 * Main entry point for the Eaglercraft Shader Collection.
 * Provides a simple one-step integration API:
 * <pre>
 * ShaderCollection.init(renderer);
 * ShaderCollection.enable("nightfall");
 * ShaderCollection.setQuality(ShaderQuality.LOW);
 * ShaderCollection.disable();
 * </pre>
 */
@OnlyIn(Dist.CLIENT)
public class ShaderCollection {
    private static final Logger LOGGER = LogManager.getLogger();

    private static ShaderCollection instance;
    private final GameRenderer gameRenderer;
    private final IResourceManager resourceManager;
    private final Map<String, ShaderProgram> programCache = new HashMap<>();
    private final ShaderCapabilities capabilities;

    private ShaderPreset currentPreset = ShaderPreset.VANILLA_ENHANCED;
    private ShaderQuality currentQuality = ShaderQuality.LOW;
    private boolean enabled = false;
    private ShaderGroup currentShaderGroup = null;
    private boolean initialised = false;
    private boolean capabilitiesDetected = false;

    private ShaderCollection(GameRenderer renderer) {
        this.gameRenderer = renderer;
        this.resourceManager = Minecraft.getInstance().getResourceManager();
        this.capabilities = new ShaderCapabilities();
    }

    /**
     * Initialise the shader collection with the game renderer.
     * This should be called once during client startup.
     *
     * @param renderer The GameRenderer instance
     * @return The ShaderCollection instance for chaining
     */
    public static ShaderCollection init(GameRenderer renderer) {
        if (instance == null) {
            instance = new ShaderCollection(renderer);
            instance.detectCapabilities();
            instance.initialised = true;
            LOGGER.info("Eaglercraft Shader Collection initialised");
        }
        return instance;
    }

    /**
     * Get the singleton instance.
     * @return The ShaderCollection instance, or null if not initialised
     */
    public static ShaderCollection getInstance() {
        return instance;
    }

    /**
     * Check if the shader collection has been initialised.
     */
    public static boolean isInitialised() {
        return instance != null && instance.initialised;
    }

    /**
     * Enable a shader preset by ID.
     * @param presetId The preset ID (e.g., "vanilla_enhanced", "nightfall", "bright")
     * @return true if the preset was successfully enabled
     */
    public boolean enable(String presetId) {
        ShaderPreset preset = ShaderPreset.fromId(presetId);
        return enable(preset);
    }

    /**
     * Enable a shader preset.
     * @param preset The preset to enable
     * @return true if the preset was successfully enabled
     */
    public boolean enable(ShaderPreset preset) {
        if (!initialised) {
            LOGGER.warn("ShaderCollection not initialised, call init() first");
            return false;
        }

        if (!capabilities.supportsShaders()) {
            LOGGER.warn("Shaders not supported on this platform");
            return false;
        }

        try {
            // Close existing shader group
            if (currentShaderGroup != null) {
                currentShaderGroup.close();
                currentShaderGroup = null;
            }

            // Load the new shader program
            String programName = getProgramName(preset, currentQuality);
            ShaderGroup shaderGroup = new ShaderGroup(
                Minecraft.getInstance().getTextureManager(),
                resourceManager,
                Minecraft.getInstance().getFramebuffer(),
                new ResourceLocation(programName)
            );

            // Create framebuffers
            shaderGroup.createBindFramebuffers(
                Minecraft.getInstance().mainWindow.getFramebufferWidth(),
                Minecraft.getInstance().mainWindow.getFramebufferHeight()
            );

            currentShaderGroup = shaderGroup;
            currentPreset = preset;
            enabled = true;

            LOGGER.info("Enabled shader preset: {} at quality: {}", preset.getDisplayName(), currentQuality.getDisplayName());
            return true;

        } catch (Exception e) {
            LOGGER.error("Failed to enable shader preset: " + preset.getId(), e);
            fallbackToVanilla();
            return false;
        }
    }

    /**
     * Set the quality level for the current preset.
     * Requires re-enabling the preset to take effect.
     * @param quality The quality level
     */
    public void setQuality(ShaderQuality quality) {
        if (currentQuality != quality) {
            currentQuality = quality;
            if (enabled) {
                enable(currentPreset);
            }
        }
    }

    /**
     * Get the current quality level.
     */
    public ShaderQuality getQuality() {
        return currentQuality;
    }

    /**
     * Get the currently active preset.
     */
    public ShaderPreset getCurrentPreset() {
        return currentPreset;
    }

    /**
     * Check if shaders are currently enabled.
     */
    public boolean isEnabled() {
        return enabled && currentShaderGroup != null;
    }

    /**
     * Disable shaders and return to vanilla rendering.
     */
    public void disable() {
        if (currentShaderGroup != null) {
            currentShaderGroup.close();
            currentShaderGroup = null;
        }
        enabled = false;
        LOGGER.info("Shaders disabled, returned to vanilla rendering");
    }

    /**
     * Toggle shaders on/off with the current preset.
     */
    public void toggle() {
        if (enabled) {
            disable();
        } else {
            enable(currentPreset);
        }
    }

    /**
     * Render the current shader (called from GameRenderer).
     * @param partialTicks Partial tick time for animation
     */
    public void render(float partialTicks) {
        if (enabled && currentShaderGroup != null && capabilities.supportsShaders()) {
            try {
                currentShaderGroup.render(partialTicks);
            } catch (Exception e) {
                LOGGER.error("Shader render error, falling back to vanilla", e);
                fallbackToVanilla();
            }
        }
    }

    /**
     * Update shader framebuffer size (call on window resize).
     * @param width New framebuffer width
     * @param height New framebuffer height
     */
    public void updateFramebufferSize(int width, int height) {
        if (currentShaderGroup != null) {
            currentShaderGroup.createBindFramebuffers(width, height);
        }
    }

    /**
     * Reload shaders (call after resource pack changes).
     */
    public void reload() {
        if (enabled) {
            enable(currentPreset);
        }
    }

    /**
     * Get the detected shader capabilities.
     */
    public ShaderCapabilities getCapabilities() {
        return capabilities;
    }

    private String getProgramName(ShaderPreset preset, ShaderQuality quality) {
        return preset.getShaderProgramName() + "_" + quality.getId();
    }

    private void detectCapabilities() {
        if (capabilitiesDetected) return;
        capabilitiesDetected = true;

        // Detect WebGL/OpenGL capabilities
        capabilities.webgl2 = EaglercraftGPU.glIsWebGL2();
        capabilities.maxTextureSize = EaglercraftGPU.glGetInteger(0x0D33); // GL_MAX_TEXTURE_SIZE
        capabilities.maxVertexUniforms = EaglercraftGPU.glGetInteger(0x8B4A); // GL_MAX_VERTEX_UNIFORM_VECTORS
        capabilities.maxFragmentUniforms = EaglercraftGPU.glGetInteger(0x8DFD); // GL_MAX_FRAGMENT_UNIFORM_VECTORS
        capabilities.maxVaryingVectors = EaglercraftGPU.glGetInteger(0x8DFC); // GL_MAX_VARYING_VECTORS
        capabilities.supportsDerivatives = EaglercraftGPU.glGetExtension("OES_standard_derivatives") != null;
        capabilities.supportsFragDepth = EaglercraftGPU.glGetExtension("EXT_frag_depth") != null;
        capabilities.supportsDrawBuffers = EaglercraftGPU.glGetExtension("WEBGL_draw_buffers") != null;

        LOGGER.info("Shader capabilities detected: WebGL2={}, MaxTex={}, MaxVertUni={}, MaxFragUni={}",
            capabilities.webgl2, capabilities.maxTextureSize,
            capabilities.maxVertexUniforms, capabilities.maxFragmentUniforms);
    }

    private void fallbackToVanilla() {
        if (currentShaderGroup != null) {
            try {
                currentShaderGroup.close();
            } catch (Exception ignored) {}
            currentShaderGroup = null;
        }
        enabled = false;
    }

    /**
     * Shader capability detection results.
     */
    @OnlyIn(Dist.CLIENT)
    public static class ShaderCapabilities {
        public boolean webgl2 = false;
        public int maxTextureSize = 2048;
        public int maxVertexUniforms = 256;
        public int maxFragmentUniforms = 256;
        public int maxVaryingVectors = 16;
        public boolean supportsDerivatives = false;
        public boolean supportsFragDepth = false;
        public boolean supportsDrawBuffers = false;

        public boolean supportsShaders() {
            return maxFragmentUniforms >= 64 && maxVertexUniforms >= 64;
        }

        public boolean isLowEnd() {
            return !webgl2 || maxFragmentUniforms < 256 || maxTextureSize < 4096;
        }
    }
}