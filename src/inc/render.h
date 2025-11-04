#ifndef RENDER_H
#define RENDER_H

#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

typedef struct Renderer Renderer;

// Renderer creation and management
Renderer* renderer_create(MTKView* metal_view);
void renderer_destroy(Renderer* renderer);
void renderer_render(Renderer* renderer);

// Text rendering
void renderer_draw_text(Renderer* renderer, const char* text, int x, int y, float r, float g, float b);
void renderer_clear(Renderer* renderer, float r, float g, float b, float a);

#endif // RENDER_H
