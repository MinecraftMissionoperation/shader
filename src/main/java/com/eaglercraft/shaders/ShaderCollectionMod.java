package com.eaglercraft.shaders;

import net.minecraft.client.Minecraft;
import net.minecraft.client.renderer.GameRenderer;
import net.minecraftforge.api.distmarker.Dist;
import net.minecraftforge.api.distmarker.OnlyIn;
import net.minecraftforge.eventbus.api.SubscribeEvent;
import net.minecraftforge.fml.common.Mod;
import net.minecraftforge.client.event.ModelBakeEvent;
import net.minecraftforge.fml.event.lifecycle.FMLClientSetupEvent;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

/**
 * Example Forge mod entry point demonstrating one-step integration.
 * 
 * To use this shader collection in your Eaglercraft client:
 * 
 * 1. Add this mod to your project dependencies
 * 2. In your client initialization code, call:
 *    <pre>
 *    EaglercraftShaderIntegration.install(gameRenderer);
 *    </pre>
 * 
 * Or if using Forge mod loading, this mod will auto-initialize.
 */
@Mod("eagler_shaders")
@OnlyIn(Dist.CLIENT)
public class ShaderCollectionMod {
    private static final Logger LOGGER = LogManager.getLogger();
    private static boolean initialised = false;

    public ShaderCollectionMod() {
        // Register for client setup event
    }

    @SubscribeEvent
    public void onClientSetup(FMLClientSetupEvent event) {
        // This runs on the client thread after Minecraft is initialised
        event.enqueueWork(() -> {
            initShaders();
        });
    }

    @SubscribeEvent
    public void onModelBake(ModelBakeEvent event) {
        // Ensure shaders are initialised after resource reload
        if (!initialised) {
            initShaders();
        }
    }

    private void initShaders() {
        try {
            Minecraft mc = Minecraft.getInstance();
            GameRenderer gameRenderer = mc.gameRenderer;
            
            if (gameRenderer != null) {
                EaglercraftShaderIntegration.install(gameRenderer);
                initialised = true;
                LOGGER.info("Eaglercraft Shader Collection auto-initialised");
            }
        } catch (Exception e) {
            LOGGER.error("Failed to auto-initialise Eaglercraft Shader Collection", e);
        }
    }

    /**
     * Manual initialisation for non-Forge environments.
     * Call this from your client code after GameRenderer is created.
     */
    public static void manualInit(GameRenderer gameRenderer) {
        if (!initialised && gameRenderer != null) {
            EaglercraftShaderIntegration.install(gameRenderer);
            initialised = true;
        }
    }
}