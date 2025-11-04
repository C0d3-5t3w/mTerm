#import <Cocoa/Cocoa.h>
#import <MetalKit/MetalKit.h>
#import <Metal/Metal.h>
#import "window.h"

typedef struct {
    NSWindow *ns_window;
    MTKView *metal_view;
    int should_close;
    InputCallback input_callback;
    void *input_context;
} WindowData;

@interface MTKViewDelegate : NSObject<MTKViewDelegate>
@property (nonatomic, assign) WindowData *window_data;
@end

@implementation MTKViewDelegate
- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
}

- (void)drawInMTKView:(MTKView *)view {
}
@end

@interface TerminalWindowDelegate : NSObject<NSWindowDelegate>
@property (nonatomic, assign) WindowData *window_data;
@end

@implementation TerminalWindowDelegate
- (BOOL)windowShouldClose:(NSWindow *)sender {
    if (self.window_data) {
        self.window_data->should_close = 1;
    }
    return YES;
}

- (void)windowWillClose:(NSNotification *)notification {
    if (self.window_data) {
        self.window_data->should_close = 1;
    }
}
@end

@interface TerminalView : MTKView
@property (nonatomic, assign) WindowData *window_data;
@end

@implementation TerminalView
- (void)keyDown:(NSEvent *)event {
    if (self.window_data && self.window_data->input_callback) {
        unsigned short key_code = event.keyCode;
        self.window_data->input_callback(
            self.window_data->input_context,
            (int)key_code,
            0  // ACTION_PRESSED
        );
    }
    [super keyDown:event];
}

- (void)keyUp:(NSEvent *)event {
    if (self.window_data && self.window_data->input_callback) {
        unsigned short key_code = event.keyCode;
        self.window_data->input_callback(
            self.window_data->input_context,
            (int)key_code,
            1  // ACTION_RELEASED
        );
    }
    [super keyUp:event];
}
@end

Window* window_create(const char* title, int width, int height) {
    @autoreleasepool {
        WindowData *window_data = (WindowData *)malloc(sizeof(WindowData));
        if (!window_data) return NULL;
        
        memset(window_data, 0, sizeof(WindowData));
        window_data->should_close = 0;
        
        NSRect frame = NSMakeRect(100, 100, width, height);
        NSWindow *ns_window = [[NSWindow alloc]
            initWithContentRect:frame
            styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable)
            backing:NSBackingStoreBuffered
            defer:NO];
        
        if (!ns_window) {
            free(window_data);
            return NULL;
        }
        
        ns_window.title = [NSString stringWithUTF8String:title];
        ns_window.backgroundColor = [NSColor blackColor];
        
        TerminalWindowDelegate *delegate = [[TerminalWindowDelegate alloc] init];
        delegate.window_data = window_data;
        ns_window.delegate = delegate;
        
        MTKView *metal_view = [[TerminalView alloc] initWithFrame:NSMakeRect(0, 0, width, height)];
        if (!metal_view) {
            [ns_window release];
            free(window_data);
            return NULL;
        }
        
        ((TerminalView *)metal_view).window_data = window_data;
        
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        if (!device) {
            [metal_view release];
            [ns_window release];
            free(window_data);
            return NULL;
        }
        
        metal_view.device = device;
        metal_view.drawableSize = CGSizeMake(width, height);
        metal_view.delegate = [[MTKViewDelegate alloc] init];
        ((MTKViewDelegate *)metal_view.delegate).window_data = window_data;
        
        [ns_window.contentView addSubview:metal_view];
        
        window_data->ns_window = ns_window;
        window_data->metal_view = metal_view;
        
        return (Window *)window_data;
    }
}

void window_destroy(Window* window) {
    if (!window) return;
    
    @autoreleasepool {
        WindowData *window_data = (WindowData *)window;
        
        if (window_data->ns_window) {
            [window_data->ns_window release];
        }
        if (window_data->metal_view) {
            [window_data->metal_view release];
        }
        
        free(window_data);
    }
}

void window_show(Window* window) {
    if (!window) return;
    
    @autoreleasepool {
        WindowData *window_data = (WindowData *)window;
        if (window_data->ns_window) {
            [window_data->ns_window makeKeyAndOrderFront:nil];
        }
    }
}

void window_close(Window* window) {
    if (!window) return;
    
    @autoreleasepool {
        WindowData *window_data = (WindowData *)window;
        if (window_data->ns_window) {
            [window_data->ns_window close];
        }
    }
}

int window_should_close(Window* window) {
    if (!window) return 1;
    
    WindowData *window_data = (WindowData *)window;
    return window_data->should_close;
}

void window_swap_buffers(Window* window) {
    // Metal handles this automatically through MTKView
}

NSWindow* window_get_nswindow(Window* window) {
    if (!window) return NULL;
    WindowData *window_data = (WindowData *)window;
    return window_data->ns_window;
}

MTKView* window_get_metal_view(Window* window) {
    if (!window) return NULL;
    WindowData *window_data = (WindowData *)window;
    return window_data->metal_view;
}

void window_set_key_callback(Window* window, InputCallback callback, void* context) {
    if (!window) return;
    
    WindowData *window_data = (WindowData *)window;
    window_data->input_callback = callback;
    window_data->input_context = context;
}
