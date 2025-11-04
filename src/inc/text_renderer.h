#ifndef TEXT_RENDERER_H
#define TEXT_RENDERER_H

typedef struct TextRenderer TextRenderer;

typedef enum {
    FONT_REGULAR,
    FONT_BOLD,
    FONT_ITALIC,
    FONT_BOLD_ITALIC,
} FontStyle;

typedef enum {
    RENDERING_BITMAP,      // Fast, simple rendering
    RENDERING_SUBPIXEL,    // Smoother rendering
    RENDERING_LCD,         // LCD font rendering
} RenderingMode;

// Text renderer creation
TextRenderer* text_renderer_create(void);
void text_renderer_destroy(TextRenderer* renderer);

// Font configuration
int text_renderer_set_font(TextRenderer* renderer, const char* font_name, float size);
int text_renderer_set_font_style(TextRenderer* renderer, FontStyle style);
int text_renderer_enable_ligatures(TextRenderer* renderer, int enable);
int text_renderer_enable_variable_width(TextRenderer* renderer, int enable);

// Rendering mode
void text_renderer_set_rendering_mode(TextRenderer* renderer, RenderingMode mode);
RenderingMode text_renderer_get_rendering_mode(TextRenderer* renderer);

// Character metrics
float text_renderer_get_char_width(TextRenderer* renderer, char c);
float text_renderer_get_char_height(TextRenderer* renderer);
float text_renderer_get_line_height(TextRenderer* renderer);

// Text rendering
int text_renderer_render_text(TextRenderer* renderer, const char* text, int x, int y);
int text_renderer_render_styled_text(TextRenderer* renderer, const char* text, FontStyle style, int x, int y);

// Ligature support
const char* text_renderer_apply_ligatures(TextRenderer* renderer, const char* text, char* out_buffer, int buffer_size);

// Font queries
const char* text_renderer_get_current_font(TextRenderer* renderer);
float text_renderer_get_current_font_size(TextRenderer* renderer);
int text_renderer_ligatures_enabled(TextRenderer* renderer);
int text_renderer_variable_width_enabled(TextRenderer* renderer);

#endif // TEXT_RENDERER_H
