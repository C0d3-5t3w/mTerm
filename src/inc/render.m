#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import "render.h"

typedef struct {
    id<MTLDevice> device;
    id<MTLCommandQueue> command_queue;
    MTKView *metal_view;
    id<MTLRenderPipelineState> pipeline_state;
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
    }
}

void renderer_draw_text(Renderer* renderer, const char* text, int x, int y, float r, float g, float b) {
    if (!renderer || !text) return;
    
    // Text rendering would typically use Core Text or other macOS APIs
    // For now, this is a placeholder that can be extended
    // In a real terminal, text would be rendered using bitmap fonts
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
