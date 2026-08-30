package com.eaglercraft.shaders;

import com.mojang.blaze3d.platform.GlStateManager;
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

/**
 * Eaglercraft-specific integration adapter for the Shader Collection.
 * This class hooks into Eaglercraft's GameRenderer and provides
 * the minimal integration layer required.
 * 
 * Usage:
 * <pre>
 * // In your client mod initialization:
 * EaglercraftShaderIntegration.install(renderer);
 * 
 * // Then use the ShaderCollection API:
 * ShaderCollection.enable("nightfall");
 * ShaderCollection.setQuality(ShaderQuality.LOW);
 * </pre>
 */
@OnlyIn(Dist.CLIENT)
public class EaglercraftShaderIntegration {
    private static final Logger LOGGER = LogManager.getLogger();
    
    private static GameRenderer gameRenderer;
    private static ShaderCollection shaderCollection;
    private static boolean installed = false;
    private static ShaderGroup vanillaShaderGroup = null;
    private static boolean wasShaderActive = false;

    /**
     * Install the shader collection into Eaglercraft's rendering pipeline.
     * This should be called once during client initialization.
     * 
     * @param renderer The GameRenderer instance
     * @return true if installation succeeded
     */
    public static boolean install(GameRenderer renderer) {
        if (installed) {
            LOGGER.warn("EaglercraftShaderIntegration already installed");
            return true;
        }

        if (renderer == null) {
            LOGGER.error("Cannot install: GameRenderer is null");
            return false;
        }

        gameRenderer = renderer;
        
        try {
            // Initialize the shader collection
            shaderCollection = ShaderCollection.init(renderer);
            
            // Enable default preset (Vanilla Enhanced LOW)
            shaderCollection.enable(ShaderPreset.VANILLA_ENHANCED);
            shaderCollection.setQuality(ShaderQuality.LOW);
            
            installed = true;
            LOGGER.info("Eaglercraft Shader Collection integration installed successfully");
            return true;
            
        } catch (Exception e) {
            LOGGER.error("Failed to install Eaglercraft Shader Collection integration", e);
            return false;
        }
    }

    /**
     * Check if the integration is installed.
     */
    public static boolean isInstalled() {
        return installed && shaderCollection != null;
    }

    /**
     * Get the shader collection instance (initialises if needed).
     */
    public static ShaderCollection getShaderCollection() {
        if (shaderCollection == null && gameRenderer != null) {
            install(gameRenderer);
        }
        return shaderCollection;
    }

    /**
     * Called from GameRenderer.updateCameraAndRender to render shaders.
     * This should be called in place of the vanilla shader rendering.
     * 
     * @param partialTicks Partial tick time
     * @param useShader Whether vanilla shaders are enabled
     */
    public static void renderShaders(float partialTicks, boolean useShader) {
        if (!installed || shaderCollection == null) {
            // Fall back to vanilla behavior
            if (useShader && gameRenderer != null) {
                ShaderGroup sg = gameRenderer.getShaderGroup();
                if (sg != null) {
                    GlStateManager.matrixMode(5890);
                    GlStateManager.pushMatrix();
                    GlStateManager.loadIdentity();
                    sg.render(partialTicks);
                    GlStateManager.popMatrix();
                }
            }
            return;
        }

        // If our shaders are enabled, render them
        if (shaderCollection.isEnabled()) {
            shaderCollection.render(partialTicks);
        } else if (useShader) {
            // Fall back to vanilla shader if our shaders are disabled but vanilla wants shaders
            ShaderGroup sg = gameRenderer.getShaderGroup();
            if (sg != null) {
                GlStateManager.matrixMode(5890);
                GlStateManager.pushMatrix();
                GlStateManager.loadIdentity();
                sg.render(partialTicks);
                GlStateManager.popMatrix();
            }
        }
    }

    /**
     * Called when the framebuffer size changes.
     */
    public static void onFramebufferResize(int width, int height) {
        if (shaderCollection != null) {
            shaderCollection.updateFramebufferSize(width, height);
        }
    }

    /**
     * Called when resources are reloaded (resource pack change).
     */
    public static void onResourceReload(IResourceManager resourceManager) {
        if (shaderCollection != null) {
            shaderCollection.reload();
        }
    }

    /**
     * Called when the game is shutting down.
     */
    public static void onShutdown() {
        if (shaderCollection != null) {
            shaderCollection.disable();
        }
        installed = false;
        gameRenderer = null;
        shaderCollection = null;
    }

    /**
     * Enable a specific shader preset by ID.
     * Convenience method that gets the collection and enables the preset.
     */
    public static boolean enablePreset(String presetId) {
        ShaderCollection sc = getShaderCollection();
        if (sc != null) {
            return sc.enable(presetId);
        }
        return false;
    }

    /**
     * Set the shader quality level.
     */
    public static void setQuality(ShaderQuality quality) {
        ShaderCollection sc = getShaderCollection();
        if (sc != null) {
            sc.setQuality(quality);
        }
    }

    /**
     * Disable all shaders and return to vanilla rendering.
     */
    public static void disableShaders() {
        ShaderCollection sc = getShaderCollection();
        if (sc != null) {
            sc.disable();
        }
    }

    /**
     * Toggle shaders on/off.
     */
    public static void toggleShaders() {
        ShaderCollection sc = getShaderCollection();
        if (sc != null) {
            sc.toggle();
        }
    }

    /**
     * Get the current preset.
     */
    public static ShaderPreset getCurrentPreset() {
        ShaderCollection sc = getShaderCollection();
        return sc != null ? sc.getCurrentPreset() : ShaderPreset.VANILLA_ENHANCED;
    }

    /**
     * Get the current quality level.
     */
    public static ShaderQuality getCurrentQuality() {
        ShaderCollection sc = getShaderCollection();
        return sc != null ? sc.getQuality() : ShaderQuality.LOW;
    }

    /**
     * Check if shaders are currently active.
     */
    public static boolean areShadersActive() {
        ShaderCollection sc = getShaderCollection();
        return sc != null && sc.isEnabled();
    }

    /**
     * Get the detected capabilities.
     */
    public static ShaderCollection.ShaderCapabilities getCapabilities() {
        ShaderCollection sc = getShaderCollection();
        return sc != null ? sc.getCapabilities() : new ShaderCollection.ShaderCapabilities();
    }

    /**
     * One-step initialisation for client developers.
     * This is the main entry point - call this once during mod init.
     * 
     * @param renderer The GameRenderer instance from Eaglercraft
     * @return The ShaderCollection instance for further configuration
     */
    public static ShaderCollection init(GameRenderer renderer) {
        return ShaderCollection.init(renderer);
    }
}