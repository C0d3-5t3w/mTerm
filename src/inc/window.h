#ifndef WINDOW_H
#define WINDOW_H

#import <Cocoa/Cocoa.h>
#import <MetalKit/MetalKit.h>

// Forward declarations
typedef struct Window Window;
typedef struct Renderer Renderer;
typedef struct Terminal Terminal;

// Window creation and management
Window* window_create(const char* title, int width, int height);
void window_destroy(Window* window);
void window_show(Window* window);
void window_close(Window* window);
int window_should_close(Window* window);
void window_swap_buffers(Window* window);

// Get underlying Cocoa objects
NSWindow* window_get_nswindow(Window* window);
MTKView* window_get_metal_view(Window* window);

// Input callbacks
typedef void (*InputCallback)(void* context, int key, int action);
void window_set_key_callback(Window* window, InputCallback callback, void* context);

// Renderer integration
void window_set_renderer(Window* window, Renderer* renderer);

// Terminal integration  
void window_set_terminal(Window* window, Terminal* terminal);

// Display update
void window_refresh(Window* window);

#endif // WINDOW_H
