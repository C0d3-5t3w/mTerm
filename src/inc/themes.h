#ifndef THEMES_H
#define THEMES_H

typedef struct Theme {
    // Basic colors
    float bg_r, bg_g, bg_b, bg_a;      // Background color
    float fg_r, fg_g, fg_b, fg_a;      // Foreground color
    
    // ANSI 16-color palette
    float colors[16][4];               // 16 colors (RGBA)
    
    // Theme properties
    char name[64];
    char author[256];
    char description[512];
    float font_size;
    int tab_height;
    char cursor_style[32];             // block, underline, bar
    float cursor_blink_rate;
} Theme;

typedef struct ThemeManager ThemeManager;

// Theme manager creation
ThemeManager* theme_manager_create(void);
void theme_manager_destroy(ThemeManager* manager);

// Theme operations
Theme* theme_manager_get_current(ThemeManager* manager);
int theme_manager_set_current(ThemeManager* manager, const char* theme_name);
const char* theme_manager_get_current_name(ThemeManager* manager);

// Built-in themes
Theme* theme_create_dark(void);
Theme* theme_create_light(void);
Theme* theme_create_solarized_dark(void);
Theme* theme_create_solarized_light(void);

// Theme manipulation
void theme_set_color(Theme* theme, int color_index, float r, float g, float b, float a);
void theme_get_color(Theme* theme, int color_index, float *r, float *g, float *b, float *a);
void theme_destroy(Theme* theme);

// Custom themes
Theme* theme_create_custom(const char* name);
int theme_manager_add_custom_theme(ThemeManager* manager, Theme* theme);
int theme_manager_remove_custom_theme(ThemeManager* manager, const char* theme_name);

// JSON import/export
int theme_export_to_json(Theme* theme, const char* filepath);
Theme* theme_import_from_json(const char* filepath);
int theme_manager_export_all_themes(ThemeManager* manager, const char* directory);
int theme_manager_import_themes_from_directory(ThemeManager* manager, const char* directory);

// Theme discovery
char** theme_manager_list_themes(ThemeManager* manager, int* out_count);
char** theme_manager_list_custom_themes(ThemeManager* manager, int* out_count);

// Theme hotkeys
int theme_manager_set_theme_hotkey(ThemeManager* manager, const char* theme_name, int key_code);
int theme_manager_get_theme_from_hotkey(ThemeManager* manager, int key_code);

#endif // THEMES_H

