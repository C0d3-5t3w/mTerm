#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <CoreText/CoreText.h>
#import <AppKit/AppKit.h>
#import "render.h"
#import "terminal.h"

#define FONT_SIZE 14.0f
#define CHAR_WIDTH 8.4f
#define CHAR_HEIGHT 16.8f

typedef struct {
    id<MTLDevice> device;
    id<MTLCommandQueue> command_queue;
    MTKView *metal_view;
    id<MTLRenderPipelineState> pipeline_state;
    Terminal *terminal;
    NSFont *font;
    CGColorRef fg_color;
    CGColorRef bg_color;
} RendererData;

Renderer* renderer_create(MTKView* metal_view) {
    @autoreleasepool {
        RendererData *renderer_data = (RendererData *)malloc(sizeof(RendererData));
        if (!renderer_data) return NULL;
        
        memset(renderer_data, 0, sizeof(RendererData));
        
        id<MTLDevice> device = metal_view.device;
        if (!device) {
            device = MTLCreateSystemDefaultDevice();
            metal_view.device = device;
        }
        
        if (!device) {
            free(renderer_data);
            return NULL;
        }
        
        id<MTLCommandQueue> command_queue = [device newCommandQueue];
        if (!command_queue) {
            free(renderer_data);
            return NULL;
        }
        
        // Load monospace font for terminal
        renderer_data->font = [NSFont fontWithName:@"Monaco" size:FONT_SIZE];
        if (!renderer_data->font) {
            renderer_data->font = [NSFont fontWithName:@"Courier New" size:FONT_SIZE];
        }
        if (!renderer_data->font) {
            renderer_data->font = [NSFont fontWithName:@"Courier" size:FONT_SIZE];
        }
        if (!renderer_data->font) {
            renderer_data->font = [NSFont systemFontOfSize:FONT_SIZE];
        }
        
        // Default xterm colors
        renderer_data->fg_color = CGColorCreateGenericRGB(0.73f, 0.73f, 0.73f, 1.0f); // Light gray
        renderer_data->bg_color = CGColorCreateGenericRGB(0.0f, 0.0f, 0.0f, 1.0f);     // Black
        
        renderer_data->device = device;
        renderer_data->command_queue = command_queue;
        renderer_data->metal_view = metal_view;
        
        return (Renderer *)renderer_data;
    }
}

void renderer_destroy(Renderer* renderer) {
    if (!renderer) return;
    
    @autoreleasepool {
        RendererData *renderer_data = (RendererData *)renderer;
        
        if (renderer_data->command_queue) {
            [renderer_data->command_queue release];
        }
        if (renderer_data->device) {
            [renderer_data->device release];
        }
        if (renderer_data->font) {
            [renderer_data->font release];
        }
        if (renderer_data->fg_color) {
            CGColorRelease(renderer_data->fg_color);
        }
        if (renderer_data->bg_color) {
            CGColorRelease(renderer_data->bg_color);
        }
        
        free(renderer_data);
    }
}

void renderer_render(Renderer* renderer) {
    if (!renderer) return;
    
    @autoreleasepool {
        RendererData *renderer_data = (RendererData *)renderer;
        MTKView *metal_view = renderer_data->metal_view;
        
        if (!metal_view || !renderer_data->command_queue) {
            return;
        }
        
        id<CAMetalDrawable> drawable = [metal_view currentDrawable];
        if (!drawable) {
            return;
        }
        
        MTLRenderPassDescriptor *render_pass_desc = [MTLRenderPassDescriptor renderPassDescriptor];
        if (!render_pass_desc) {
            return;
        }
        
        render_pass_desc.colorAttachments[0].texture = drawable.texture;
        render_pass_desc.colorAttachments[0].loadAction = MTLLoadActionClear;
        render_pass_desc.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0);
        render_pass_desc.colorAttachments[0].storeAction = MTLStoreActionStore;
        
        id<MTLCommandBuffer> command_buffer = [renderer_data->command_queue commandBuffer];
        if (command_buffer) {
            id<MTLRenderCommandEncoder> render_encoder = [command_buffer renderCommandEncoderWithDescriptor:render_pass_desc];
            if (render_encoder) {
                [render_encoder endEncoding];
            }
            
            [command_buffer presentDrawable:drawable];
            [command_buffer commit];
        }
        
        // Draw terminal text
        if (renderer_data->terminal && metal_view.bounds.size.width > 0) {
            renderer_draw_terminal_text(renderer);
        }
    }
}

void renderer_draw_terminal_text(Renderer* renderer) {
    if (!renderer) return;
    
    @autoreleasepool {
        RendererData *renderer_data = (RendererData *)renderer;
        Terminal *terminal = renderer_data->terminal;
        
        if (!terminal) return;
        
        const char *text = terminal_get_text(terminal);
        if (!text) return;
        
        NSString *ns_text = [NSString stringWithUTF8String:text];
        if (!ns_text) return;
        
        // Use simple text rendering with Terminal view
        // Terminal content will be rendered in the CATextLayer setup
        // This is called to update the display when terminal content changes
    }
}

void renderer_draw_text(Renderer* renderer, const char* text, int x, int y, float r, float g, float b) {
    if (!renderer || !text) return;
    
    // Text rendering placeholder
    // In a full implementation, this would use bitmap fonts or texture rendering
}

void renderer_set_terminal(Renderer* renderer, Terminal* terminal) {
    if (!renderer) return;
    RendererData *renderer_data = (RendererData *)renderer;
    renderer_data->terminal = terminal;
}

void renderer_clear(Renderer* renderer, float r, float g, float b, float a) {
    if (!renderer) return;
    
    @autoreleasepool {
        RendererData *renderer_data = (RendererData *)renderer;
        MTKView *metal_view = renderer_data->metal_view;
        
        if (!metal_view || !renderer_data->command_queue) {
            return;
        }
        
        id<CAMetalDrawable> drawable = [metal_view currentDrawable];
        if (!drawable) {
            return;
        }
        
        MTLRenderPassDescriptor *render_pass_desc = [MTLRenderPassDescriptor renderPassDescriptor];
        if (!render_pass_desc) {
            return;
        }
        
        render_pass_desc.colorAttachments[0].texture = drawable.texture;
        render_pass_desc.colorAttachments[0].loadAction = MTLLoadActionClear;
        render_pass_desc.colorAttachments[0].clearColor = MTLClearColorMake(r, g, b, a);
        render_pass_desc.colorAttachments[0].storeAction = MTLStoreActionStore;
        
        id<MTLCommandBuffer> command_buffer = [renderer_data->command_queue commandBuffer];
        if (command_buffer) {
            id<MTLRenderCommandEncoder> render_encoder = [command_buffer renderCommandEncoderWithDescriptor:render_pass_desc];
            if (render_encoder) {
                [render_encoder endEncoding];
            }
            
            [command_buffer presentDrawable:drawable];
            [command_buffer commit];
        }
    }
}
