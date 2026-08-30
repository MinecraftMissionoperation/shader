package com.eaglercraft.shaders;

import net.minecraftforge.api.distmarker.Dist;
import net.minecraftforge.api.distmarker.OnlyIn;

/**
 * Shader presets available in the collection.
 * LIGHT presets: Vanilla Enhanced, Bright, Soft
 * DARK presets: Nightfall, Noir, Abyss
 */
@OnlyIn(Dist.CLIENT)
public enum ShaderPreset {
    // LIGHT PRESETS
    VANILLA_ENHANCED("vanilla_enhanced", "Vanilla Enhanced", ShaderCategory.LIGHT,
        "Improved colour balance, better sunlight, lightweight fog, improved sky"),
    BRIGHT("bright", "Bright", ShaderCategory.LIGHT,
        "Brighter lighting, clearer atmosphere, more vibrant colours"),
    SOFT("soft", "Soft", ShaderCategory.LIGHT,
        "Gentle colour transitions, reduced harsh lighting, subtle atmosphere"),

    // DARK PRESETS
    NIGHTFALL("nightfall", "Nightfall", ShaderCategory.DARK,
        "Darker ambient, increased contrast, atmospheric fog, nighttime mood"),
    NOIR("noir", "Noir", ShaderCategory.DARK,
        "High contrast, dark appearance, reduced saturation, strong visual identity"),
    ABYSS("abyss", "Abyss", ShaderCategory.DARK,
        "Deep shadows, cool/dark colour grading, atmospheric darkness");

    private final String id;
    private final String displayName;
    private final ShaderCategory category;
    private final String description;

    ShaderPreset(String id, String displayName, ShaderCategory category, String description) {
        this.id = id;
        this.displayName = displayName;
        this.category = category;
        this.description = description;
    }

    public String getId() {
        return id;
    }

    public String getDisplayName() {
        return displayName;
    }

    public ShaderCategory getCategory() {
        return category;
    }

    public String getDescription() {
        return description;
    }

    public String getShaderProgramName() {
        return "eagler_shaders/" + id;
    }

    public static ShaderPreset fromId(String id) {
        for (ShaderPreset preset : values()) {
            if (preset.id.equalsIgnoreCase(id)) {
                return preset;
            }
        }
        return VANILLA_ENHANCED;
    }

    public static ShaderPreset[] getLightPresets() {
        return new ShaderPreset[]{VANILLA_ENHANCED, BRIGHT, SOFT};
    }

    public static ShaderPreset[] getDarkPresets() {
        return new ShaderPreset[]{NIGHTFALL, NOIR, ABYSS};
    }

    public static ShaderPreset[] getAllPresets() {
        return values();
    }
}

@OnlyIn(Dist.CLIENT)
enum ShaderCategory {
    LIGHT,
    DARK
}