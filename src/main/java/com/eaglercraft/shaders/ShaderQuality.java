package com.eaglercraft.shaders;

import net.minecraftforge.api.distmarker.Dist;
import net.minecraftforge.api.distmarker.OnlyIn;

/**
 * Quality levels for shader presets.
 * LOW: Aggressively optimised for weak integrated GPUs and older devices.
 * MEDIUM: Balanced visuals and FPS.
 * HIGH: Additional optional visual improvements if stable.
 */
@OnlyIn(Dist.CLIENT)
public enum ShaderQuality {
    LOW("low", "Low", "Optimised for weak integrated GPUs"),
    MEDIUM("medium", "Medium", "Balanced visuals and performance"),
    HIGH("high", "High", "Best visuals on capable hardware");

    private final String id;
    private final String displayName;
    private final String description;

    ShaderQuality(String id, String displayName, String description) {
        this.id = id;
        this.displayName = displayName;
        this.description = description;
    }

    public String getId() {
        return id;
    }

    public String getDisplayName() {
        return displayName;
    }

    public String getDescription() {
        return description;
    }

    public static ShaderQuality fromId(String id) {
        for (ShaderQuality quality : values()) {
            if (quality.id.equalsIgnoreCase(id)) {
                return quality;
            }
        }
        return LOW;
    }

    public static ShaderQuality fromOrdinal(int ordinal) {
        if (ordinal >= 0 && ordinal < values().length) {
            return values()[ordinal];
        }
        return LOW;
    }
}