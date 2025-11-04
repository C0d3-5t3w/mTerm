#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "image_renderer.h"

typedef struct {
    char filepath[1024];
    int width;
    int height;
    ImageFormat format;
} TerminalImageData;

typedef struct {
    TerminalImageData **images;
    int image_count;
    int max_images;
} ImageRendererData;

ImageRenderer* image_renderer_create(void) {
    ImageRendererData *renderer = (ImageRendererData *)malloc(sizeof(ImageRendererData));
    if (!renderer) return NULL;
    
    memset(renderer, 0, sizeof(ImageRendererData));
    
    renderer->max_images = 100;
    renderer->images = (TerminalImageData **)malloc(sizeof(TerminalImageData *) * renderer->max_images);
    if (!renderer->images) {
        free(renderer);
        return NULL;
    }
    
    memset(renderer->images, 0, sizeof(TerminalImageData *) * renderer->max_images);
    
    return (ImageRenderer *)renderer;
}

void image_renderer_destroy(ImageRenderer* renderer) {
    if (!renderer) return;
    
    image_renderer_clear_images(renderer);
    free(((ImageRendererData *)renderer)->images);
    free(renderer);
}

int image_renderer_handle_escape_sequence(ImageRenderer* renderer, const char* sequence) {
    if (!renderer || !sequence) return -1;
    
    char filepath[1024];
    memset(filepath, 0, sizeof(filepath));
    
    if (image_renderer_parse_iTerm2_image_protocol(sequence, filepath, sizeof(filepath)) == 0) {
        TerminalImage *image = image_renderer_load_image(renderer, filepath);
        return image ? 0 : -1;
    }
    
    return -1;
}

TerminalImage* image_renderer_load_image(ImageRenderer* renderer, const char* filepath) {
    if (!renderer || !filepath) return NULL;
    
    ImageRendererData *renderer_data = (ImageRendererData *)renderer;
    
    if (renderer_data->image_count >= renderer_data->max_images) return NULL;
    
    @autoreleasepool {
        NSString *path = [NSString stringWithUTF8String:filepath];
        NSImage *ns_image = [[NSImage alloc] initWithContentsOfFile:path];
        
        if (!ns_image) return NULL;
        
        TerminalImageData *image = (TerminalImageData *)malloc(sizeof(TerminalImageData));
        if (!image) return NULL;
        
        memset(image, 0, sizeof(TerminalImageData));
        
        strncpy(image->filepath, filepath, sizeof(image->filepath) - 1);
        image->width = (int)ns_image.size.width;
        image->height = (int)ns_image.size.height;
        
        // Detect format from file extension
        NSString *ext = [path pathExtension].lowercaseString;
        if ([ext isEqualToString:@"png"]) {
            image->format = IMG_PNG;
        } else if ([ext isEqualToString:@"jpg"] || [ext isEqualToString:@"jpeg"]) {
            image->format = IMG_JPEG;
        } else if ([ext isEqualToString:@"gif"]) {
            image->format = IMG_GIF;
        } else if ([ext isEqualToString:@"webp"]) {
            image->format = IMG_WEBP;
        }
        
        renderer_data->images[renderer_data->image_count] = image;
        renderer_data->image_count++;
        
        return (TerminalImage *)image;
    }
}

void image_renderer_display_image(ImageRenderer* renderer, TerminalImage* image, int x, int y) {
    // Implementation would handle display logic
    // This is a placeholder for rendering infrastructure
    if (!renderer || !image) return;
}

int image_renderer_get_image_width(TerminalImage* image) {
    if (!image) return 0;
    return ((TerminalImageData *)image)->width;
}

int image_renderer_get_image_height(TerminalImage* image) {
    if (!image) return 0;
    return ((TerminalImageData *)image)->height;
}

ImageFormat image_renderer_get_image_format(TerminalImage* image) {
    if (!image) return IMG_PNG;
    return ((TerminalImageData *)image)->format;
}

const char* image_renderer_get_image_path(TerminalImage* image) {
    if (!image) return NULL;
    return ((TerminalImageData *)image)->filepath;
}

void image_renderer_clear_images(ImageRenderer* renderer) {
    if (!renderer) return;
    
    ImageRendererData *renderer_data = (ImageRendererData *)renderer;
    
    for (int i = 0; i < renderer_data->image_count; i++) {
        if (renderer_data->images[i]) {
            free(renderer_data->images[i]);
        }
    }
    
    renderer_data->image_count = 0;
}

void image_renderer_destroy_image(TerminalImage* image) {
    if (!image) return;
    free(image);
}

int image_renderer_parse_iTerm2_image_protocol(const char* sequence, char* out_filepath, int filepath_size) {
    if (!sequence || !out_filepath) return -1;
    
    // Parse iTerm2 inline image protocol: OSC 1337 ; File=...
    // Format: \033]1337;File=name=<name>;size=<size>;width=<width>;<data>\007
    
    const char *start = strstr(sequence, "name=");
    if (!start) return -1;
    
    start += 5;
    const char *end = strchr(start, ';');
    if (!end) end = strchr(start, ':');
    
    if (!end) return -1;
    
    int len = end - start;
    if (len >= filepath_size) return -1;
    
    strncpy(out_filepath, start, len);
    out_filepath[len] = '\0';
    
    return 0;
}
