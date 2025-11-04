#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <CoreText/CoreText.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "text_renderer.h"

typedef struct {
    NSFont *font;
    float font_size;
    FontStyle font_style;
    int ligatures_enabled;
    int variable_width_enabled;
    RenderingMode rendering_mode;
    char font_name[256];
    float char_width;
    float char_height;
    float line_height;
} TextRendererData;

TextRenderer* text_renderer_create(void) {
    TextRendererData *renderer = (TextRendererData *)malloc(sizeof(TextRendererData));
    if (!renderer) return NULL;
    
    memset(renderer, 0, sizeof(TextRendererData));
    
    // Default values
    renderer->font_size = 14.0f;
    renderer->font_style = FONT_REGULAR;
    renderer->ligatures_enabled = 1;
    renderer->variable_width_enabled = 0;
    renderer->rendering_mode = RENDERING_BITMAP;
    strcpy(renderer->font_name, "Monaco");
    
    @autoreleasepool {
        renderer->font = [NSFont fontWithName:@"Monaco" size:14.0f];
        
        NSDictionary *dict = @{NSFontAttributeName: renderer->font};
        NSSize size = [@"X" sizeWithAttributes:dict];
        
        renderer->char_width = size.width;
        renderer->char_height = size.height;
        renderer->line_height = size.height * 1.2f;
    }
    
    return (TextRenderer *)renderer;
}

void text_renderer_destroy(TextRenderer* renderer) {
    if (!renderer) return;
    free(renderer);
}

int text_renderer_set_font(TextRenderer* renderer, const char* font_name, float size) {
    if (!renderer || !font_name || size <= 0) return -1;
    
    TextRendererData *renderer_data = (TextRendererData *)renderer;
    
    @autoreleasepool {
        NSString *font_ns = [NSString stringWithUTF8String:font_name];
        NSFont *new_font = [NSFont fontWithName:font_ns size:size];
        
        if (!new_font) return -1;
        
        renderer_data->font = new_font;
        renderer_data->font_size = size;
        strncpy(renderer_data->font_name, font_name, sizeof(renderer_data->font_name) - 1);
        
        // Recalculate character metrics
        NSDictionary *dict = @{NSFontAttributeName: new_font};
        NSSize char_size = [@"X" sizeWithAttributes:dict];
        
        renderer_data->char_width = char_size.width;
        renderer_data->char_height = char_size.height;
        renderer_data->line_height = char_size.height * 1.2f;
        
        return 0;
    }
}

int text_renderer_set_font_style(TextRenderer* renderer, FontStyle style) {
    if (!renderer) return -1;
    
    TextRendererData *renderer_data = (TextRendererData *)renderer;
    renderer_data->font_style = style;
    
    return 0;
}

int text_renderer_enable_ligatures(TextRenderer* renderer, int enable) {
    if (!renderer) return -1;
    
    TextRendererData *renderer_data = (TextRendererData *)renderer;
    renderer_data->ligatures_enabled = enable;
    
    return 0;
}

int text_renderer_enable_variable_width(TextRenderer* renderer, int enable) {
    if (!renderer) return -1;
    
    TextRendererData *renderer_data = (TextRendererData *)renderer;
    renderer_data->variable_width_enabled = enable;
    
    return 0;
}

void text_renderer_set_rendering_mode(TextRenderer* renderer, RenderingMode mode) {
    if (!renderer) return;
    ((TextRendererData *)renderer)->rendering_mode = mode;
}

RenderingMode text_renderer_get_rendering_mode(TextRenderer* renderer) {
    if (!renderer) return RENDERING_BITMAP;
    return ((TextRendererData *)renderer)->rendering_mode;
}

float text_renderer_get_char_width(TextRenderer* renderer, char c) {
    if (!renderer) return 0.0f;
    
    TextRendererData *renderer_data = (TextRendererData *)renderer;
    
    if (renderer_data->variable_width_enabled) {
        @autoreleasepool {
            NSString *char_str = [NSString stringWithFormat:@"%c", c];
            NSDictionary *dict = @{NSFontAttributeName: renderer_data->font};
            NSSize size = [char_str sizeWithAttributes:dict];
            return size.width;
        }
    }
    
    return renderer_data->char_width;
}

float text_renderer_get_char_height(TextRenderer* renderer) {
    if (!renderer) return 0.0f;
    return ((TextRendererData *)renderer)->char_height;
}

float text_renderer_get_line_height(TextRenderer* renderer) {
    if (!renderer) return 0.0f;
    return ((TextRendererData *)renderer)->line_height;
}

int text_renderer_render_text(TextRenderer* renderer, const char* text, int x, int y) {
    if (!renderer || !text) return -1;
    
    // Rendering implementation would go here
    // This is a placeholder for the infrastructure
    
    return 0;
}

int text_renderer_render_styled_text(TextRenderer* renderer, const char* text, FontStyle style, int x, int y) {
    if (!renderer || !text) return -1;
    
    // Rendering with style implementation
    // This is a placeholder for the infrastructure
    
    return 0;
}

const char* text_renderer_apply_ligatures(TextRenderer* renderer, const char* text, char* out_buffer, int buffer_size) {
    if (!renderer || !text || !out_buffer || buffer_size <= 0) return NULL;
    
    TextRendererData *renderer_data = (TextRendererData *)renderer;
    
    if (!renderer_data->ligatures_enabled) {
        strncpy(out_buffer, text, buffer_size - 1);
        out_buffer[buffer_size - 1] = '\0';
        return out_buffer;
    }
    
    // Common ligatures replacements
    const char *replacements[][2] = {
        {"fi", "ﬁ"},
        {"fl", "ﬂ"},
        {"ff", "ﬀ"},
        {"ffi", "ﬃ"},
        {"ffl", "ﬄ"},
        {"->", "→"},
        {"=>", "⇒"},
        {"<-", "←"},
        {"<=", "⇐"},
        {NULL, NULL}
    };
    
    strncpy(out_buffer, text, buffer_size - 1);
    out_buffer[buffer_size - 1] = '\0';
    
    return out_buffer;
}

const char* text_renderer_get_current_font(TextRenderer* renderer) {
    if (!renderer) return NULL;
    return ((TextRendererData *)renderer)->font_name;
}

float text_renderer_get_current_font_size(TextRenderer* renderer) {
    if (!renderer) return 0.0f;
    return ((TextRendererData *)renderer)->font_size;
}

int text_renderer_ligatures_enabled(TextRenderer* renderer) {
    if (!renderer) return 0;
    return ((TextRendererData *)renderer)->ligatures_enabled;
}

int text_renderer_variable_width_enabled(TextRenderer* renderer) {
    if (!renderer) return 0;
    return ((TextRendererData *)renderer)->variable_width_enabled;
}
