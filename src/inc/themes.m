#include <stdlib.h>
#include <string.h>
#include "themes.h"

typedef struct {
    Theme *current_theme;
    Theme *dark_theme;
    Theme *light_theme;
    Theme *solarized_dark_theme;
    Theme *solarized_light_theme;
    char current_theme_name[64];
} ThemeManagerData;

// Helper to create ANSI colors
static void set_ansi_palette(Theme* theme, const float colors[16][4]) {
    for (int i = 0; i < 16; i++) {
        theme->colors[i][0] = colors[i][0];
        theme->colors[i][1] = colors[i][1];
        theme->colors[i][2] = colors[i][2];
        theme->colors[i][3] = colors[i][3];
    }
}

Theme* theme_create_dark(void) {
    Theme* theme = (Theme *)malloc(sizeof(Theme));
    if (!theme) return NULL;
    
    memset(theme, 0, sizeof(Theme));
    
    strcpy(theme->name, "Dark");
    theme->bg_r = 0.0f;
    theme->bg_g = 0.0f;
    theme->bg_b = 0.0f;
    theme->bg_a = 1.0f;
    
    theme->fg_r = 0.93f;  // #EEEEEE
    theme->fg_g = 0.93f;
    theme->fg_b = 0.93f;
    theme->fg_a = 1.0f;
    
    theme->font_size = 14.0f;
    theme->tab_height = 24;
    
    // xterm color palette
    const float ansi_colors[16][4] = {
        {0.00f, 0.00f, 0.00f, 1.0f},  // 0: black
        {0.80f, 0.00f, 0.00f, 1.0f},  // 1: red
        {0.00f, 0.80f, 0.00f, 1.0f},  // 2: green
        {0.80f, 0.80f, 0.00f, 1.0f},  // 3: yellow
        {0.00f, 0.00f, 0.80f, 1.0f},  // 4: blue
        {0.80f, 0.00f, 0.80f, 1.0f},  // 5: magenta
        {0.00f, 0.80f, 0.80f, 1.0f},  // 6: cyan
        {0.75f, 0.75f, 0.75f, 1.0f},  // 7: white (light gray)
        {0.50f, 0.50f, 0.50f, 1.0f},  // 8: bright black (dark gray)
        {1.00f, 0.00f, 0.00f, 1.0f},  // 9: bright red
        {0.00f, 1.00f, 0.00f, 1.0f},  // 10: bright green
        {1.00f, 1.00f, 0.00f, 1.0f},  // 11: bright yellow
        {0.00f, 0.00f, 1.00f, 1.0f},  // 12: bright blue
        {1.00f, 0.00f, 1.00f, 1.0f},  // 13: bright magenta
        {0.00f, 1.00f, 1.00f, 1.0f},  // 14: bright cyan
        {1.00f, 1.00f, 1.00f, 1.0f},  // 15: bright white
    };
    
    set_ansi_palette(theme, ansi_colors);
    
    return theme;
}

Theme* theme_create_light(void) {
    Theme* theme = (Theme *)malloc(sizeof(Theme));
    if (!theme) return NULL;
    
    memset(theme, 0, sizeof(Theme));
    
    strcpy(theme->name, "Light");
    theme->bg_r = 1.00f;  // White
    theme->bg_g = 1.00f;
    theme->bg_b = 1.00f;
    theme->bg_a = 1.0f;
    
    theme->fg_r = 0.13f;  // Dark gray
    theme->fg_g = 0.13f;
    theme->fg_b = 0.13f;
    theme->fg_a = 1.0f;
    
    theme->font_size = 14.0f;
    theme->tab_height = 24;
    
    // xterm color palette (light background adjusted)
    const float ansi_colors[16][4] = {
        {0.00f, 0.00f, 0.00f, 1.0f},  // 0: black
        {0.60f, 0.00f, 0.00f, 1.0f},  // 1: red
        {0.00f, 0.60f, 0.00f, 1.0f},  // 2: green
        {0.60f, 0.60f, 0.00f, 1.0f},  // 3: yellow
        {0.00f, 0.00f, 0.80f, 1.0f},  // 4: blue
        {0.60f, 0.00f, 0.60f, 1.0f},  // 5: magenta
        {0.00f, 0.60f, 0.60f, 1.0f},  // 6: cyan
        {0.50f, 0.50f, 0.50f, 1.0f},  // 7: white
        {0.80f, 0.80f, 0.80f, 1.0f},  // 8: bright black (light gray)
        {1.00f, 0.00f, 0.00f, 1.0f},  // 9: bright red
        {0.00f, 1.00f, 0.00f, 1.0f},  // 10: bright green
        {1.00f, 1.00f, 0.00f, 1.0f},  // 11: bright yellow
        {0.00f, 0.00f, 1.00f, 1.0f},  // 12: bright blue
        {1.00f, 0.00f, 1.00f, 1.0f},  // 13: bright magenta
        {0.00f, 1.00f, 1.00f, 1.0f},  // 14: bright cyan
        {1.00f, 1.00f, 1.00f, 1.0f},  // 15: bright white
    };
    
    set_ansi_palette(theme, ansi_colors);
    
    return theme;
}

Theme* theme_create_solarized_dark(void) {
    Theme* theme = (Theme *)malloc(sizeof(Theme));
    if (!theme) return NULL;
    
    memset(theme, 0, sizeof(Theme));
    
    strcpy(theme->name, "Solarized Dark");
    theme->bg_r = 0.00f;   // #002B36
    theme->bg_g = 0.17f;
    theme->bg_b = 0.21f;
    theme->bg_a = 1.0f;
    
    theme->fg_r = 0.93f;   // #839496
    theme->fg_g = 0.58f;
    theme->fg_b = 0.59f;
    theme->fg_a = 1.0f;
    
    theme->font_size = 14.0f;
    theme->tab_height = 24;
    
    // Solarized palette
    const float ansi_colors[16][4] = {
        {0.00f, 0.17f, 0.21f, 1.0f},  // 0: base02
        {0.86f, 0.19f, 0.18f, 1.0f},  // 1: red
        {0.52f, 0.60f, 0.00f, 1.0f},  // 2: green
        {0.71f, 0.54f, 0.00f, 1.0f},  // 3: yellow
        {0.15f, 0.55f, 0.82f, 1.0f},  // 4: blue
        {0.83f, 0.40f, 0.56f, 1.0f},  // 5: magenta
        {0.16f, 0.63f, 0.60f, 1.0f},  // 6: cyan
        {0.93f, 0.91f, 0.84f, 1.0f},  // 7: base0
        {0.00f, 0.43f, 0.45f, 1.0f},  // 8: base03
        {0.99f, 0.34f, 0.36f, 1.0f},  // 9: bright red
        {0.58f, 0.63f, 0.00f, 1.0f},  // 10: bright green
        {0.99f, 0.68f, 0.00f, 1.0f},  // 11: bright yellow
        {0.37f, 0.71f, 0.99f, 1.0f},  // 12: bright blue
        {0.99f, 0.48f, 0.77f, 1.0f},  // 13: bright magenta
        {0.32f, 0.82f, 0.85f, 1.0f},  // 14: bright cyan
        {0.99f, 0.96f, 0.89f, 1.0f},  // 15: base3
    };
    
    set_ansi_palette(theme, ansi_colors);
    
    return theme;
}

Theme* theme_create_solarized_light(void) {
    Theme* theme = (Theme *)malloc(sizeof(Theme));
    if (!theme) return NULL;
    
    memset(theme, 0, sizeof(Theme));
    
    strcpy(theme->name, "Solarized Light");
    theme->bg_r = 0.99f;   // #FDF6E3
    theme->bg_g = 0.96f;
    theme->bg_b = 0.89f;
    theme->bg_a = 1.0f;
    
    theme->fg_r = 0.51f;   // #657B83
    theme->fg_g = 0.48f;
    theme->fg_b = 0.51f;
    theme->fg_a = 1.0f;
    
    theme->font_size = 14.0f;
    theme->tab_height = 24;
    
    // Solarized light palette
    const float ansi_colors[16][4] = {
        {0.99f, 0.96f, 0.89f, 1.0f},  // 0: base3
        {0.86f, 0.19f, 0.18f, 1.0f},  // 1: red
        {0.52f, 0.60f, 0.00f, 1.0f},  // 2: green
        {0.71f, 0.54f, 0.00f, 1.0f},  // 3: yellow
        {0.15f, 0.55f, 0.82f, 1.0f},  // 4: blue
        {0.83f, 0.40f, 0.56f, 1.0f},  // 5: magenta
        {0.16f, 0.63f, 0.60f, 1.0f},  // 6: cyan
        {0.00f, 0.43f, 0.45f, 1.0f},  // 7: base03
        {0.93f, 0.91f, 0.84f, 1.0f},  // 8: base0
        {0.99f, 0.34f, 0.36f, 1.0f},  // 9: bright red
        {0.58f, 0.63f, 0.00f, 1.0f},  // 10: bright green
        {0.99f, 0.68f, 0.00f, 1.0f},  // 11: bright yellow
        {0.37f, 0.71f, 0.99f, 1.0f},  // 12: bright blue
        {0.99f, 0.48f, 0.77f, 1.0f},  // 13: bright magenta
        {0.32f, 0.82f, 0.85f, 1.0f},  // 14: bright cyan
        {0.00f, 0.17f, 0.21f, 1.0f},  // 15: base02
    };
    
    set_ansi_palette(theme, ansi_colors);
    
    return theme;
}

ThemeManager* theme_manager_create(void) {
    ThemeManagerData *manager = (ThemeManagerData *)malloc(sizeof(ThemeManagerData));
    if (!manager) return NULL;
    
    memset(manager, 0, sizeof(ThemeManagerData));
    
    // Create all built-in themes
    manager->dark_theme = theme_create_dark();
    manager->light_theme = theme_create_light();
    manager->solarized_dark_theme = theme_create_solarized_dark();
    manager->solarized_light_theme = theme_create_solarized_light();
    
    // Set dark as default
    manager->current_theme = manager->dark_theme;
    strcpy(manager->current_theme_name, "Dark");
    
    return (ThemeManager *)manager;
}

void theme_manager_destroy(ThemeManager* manager) {
    if (!manager) return;
    
    ThemeManagerData *manager_data = (ThemeManagerData *)manager;
    
    if (manager_data->dark_theme) theme_destroy(manager_data->dark_theme);
    if (manager_data->light_theme) theme_destroy(manager_data->light_theme);
    if (manager_data->solarized_dark_theme) theme_destroy(manager_data->solarized_dark_theme);
    if (manager_data->solarized_light_theme) theme_destroy(manager_data->solarized_light_theme);
    
    free(manager_data);
}

Theme* theme_manager_get_current(ThemeManager* manager) {
    if (!manager) return NULL;
    
    ThemeManagerData *manager_data = (ThemeManagerData *)manager;
    return manager_data->current_theme;
}

int theme_manager_set_current(ThemeManager* manager, const char* theme_name) {
    if (!manager || !theme_name) return -1;
    
    ThemeManagerData *manager_data = (ThemeManagerData *)manager;
    
    if (strcmp(theme_name, "Dark") == 0) {
        manager_data->current_theme = manager_data->dark_theme;
    } else if (strcmp(theme_name, "Light") == 0) {
        manager_data->current_theme = manager_data->light_theme;
    } else if (strcmp(theme_name, "Solarized Dark") == 0) {
        manager_data->current_theme = manager_data->solarized_dark_theme;
    } else if (strcmp(theme_name, "Solarized Light") == 0) {
        manager_data->current_theme = manager_data->solarized_light_theme;
    } else {
        return -1;  // Theme not found
    }
    
    strcpy(manager_data->current_theme_name, theme_name);
    return 0;
}

const char* theme_manager_get_current_name(ThemeManager* manager) {
    if (!manager) return NULL;
    
    ThemeManagerData *manager_data = (ThemeManagerData *)manager;
    return manager_data->current_theme_name;
}

void theme_set_color(Theme* theme, int color_index, float r, float g, float b, float a) {
    if (!theme || color_index < 0 || color_index >= 16) return;
    
    theme->colors[color_index][0] = r;
    theme->colors[color_index][1] = g;
    theme->colors[color_index][2] = b;
    theme->colors[color_index][3] = a;
}

void theme_get_color(Theme* theme, int color_index, float *r, float *g, float *b, float *a) {
    if (!theme || !r || !g || !b || !a || color_index < 0 || color_index >= 16) return;
    
    *r = theme->colors[color_index][0];
    *g = theme->colors[color_index][1];
    *b = theme->colors[color_index][2];
    *a = theme->colors[color_index][3];
}

void theme_destroy(Theme* theme) {
    if (!theme) return;
    free(theme);
}
