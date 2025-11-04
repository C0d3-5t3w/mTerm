#ifndef IMAGE_RENDERER_H
#define IMAGE_RENDERER_H

typedef struct ImageRenderer ImageRenderer;
typedef struct TerminalImage TerminalImage;

typedef enum {
    IMG_PNG,
    IMG_JPEG,
    IMG_GIF,
    IMG_WEBP,
} ImageFormat;

// Image renderer creation
ImageRenderer* image_renderer_create(void);
void image_renderer_destroy(ImageRenderer* renderer);

// Image handling (iTerm2 protocol)
int image_renderer_handle_escape_sequence(ImageRenderer* renderer, const char* sequence);
TerminalImage* image_renderer_load_image(ImageRenderer* renderer, const char* filepath);
void image_renderer_display_image(ImageRenderer* renderer, TerminalImage* image, int x, int y);

// Image properties
int image_renderer_get_image_width(TerminalImage* image);
int image_renderer_get_image_height(TerminalImage* image);
ImageFormat image_renderer_get_image_format(TerminalImage* image);
const char* image_renderer_get_image_path(TerminalImage* image);

// Image cleanup
void image_renderer_clear_images(ImageRenderer* renderer);
void image_renderer_destroy_image(TerminalImage* image);

// iTerm2 protocol support
int image_renderer_parse_iTerm2_image_protocol(const char* sequence, char* out_filepath, int filepath_size);

#endif // IMAGE_RENDERER_H
