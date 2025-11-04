#import <Cocoa/Cocoa.h>
#import <MetalKit/MetalKit.h>
#import <Metal/Metal.h>
#import <QuartzCore/QuartzCore.h>
#import "window.h"
#import "render.h"
#import "terminal.h"

// Forward declarations
@class TerminalWindowDelegate;

typedef struct {
    NSWindow *ns_window;
    MTKView *metal_view;
    TerminalWindowDelegate *delegate;
    CATextLayer *text_layer;
    Terminal *terminal;
    int should_close;
    InputCallback input_callback;
    void *input_context;
} WindowData;

@interface MTKViewDelegate : NSObject<MTKViewDelegate>
@property (nonatomic, assign) WindowData *window_data;
@property (nonatomic, assign) Renderer *renderer;
@property (nonatomic, strong) NSFont *terminal_font;
@end

@implementation MTKViewDelegate
- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
}

- (void)drawInMTKView:(MTKView *)view {
    // This is called automatically by MTKView on each frame
    // First render Metal background
    if (self.renderer) {
        renderer_clear(self.renderer, 0.0f, 0.0f, 0.0f, 1.0f);
        renderer_render(self.renderer);
    }
    
    // Then draw terminal text using Core Graphics
    [self drawTerminalText:view];
}

- (void)drawTerminalText:(MTKView *)view {
    if (!self.window_data || !self.window_data->terminal) return;
    
    Terminal *terminal = self.window_data->terminal;
    const char *text = terminal_get_text(terminal);
    if (!text) return;
    
    NSString *ns_text = [NSString stringWithUTF8String:text];
    if (!ns_text) return;
    
    // Setup font
    if (!self.terminal_font) {
        self.terminal_font = [NSFont fontWithName:@"Monaco" size:13.0];
        if (!self.terminal_font) {
            self.terminal_font = [NSFont fontWithName:@"Courier New" size:13.0];
        }
        if (!self.terminal_font) {
            self.terminal_font = [NSFont fontWithName:@"Courier" size:13.0];
        }
        if (!self.terminal_font) {
            self.terminal_font = [NSFont systemFontOfSize:13.0];
        }
    }
    
    // Create text attributes
    NSDictionary *attrs = @{
        NSFontAttributeName: self.terminal_font,
        NSForegroundColorAttributeName: [NSColor colorWithRed:0.73 green:0.73 blue:0.73 alpha:1.0]
    };
    
    // Draw terminal content
    NSArray *lines = [ns_text componentsSeparatedByString:@"\n"];
    CGFloat y_offset = 10;
    CGFloat x_offset = 10;
    
    for (NSString *line in lines) {
        [line drawAtPoint:CGPointMake(x_offset, y_offset) withAttributes:attrs];
        y_offset += 17;
    }
    
    // Draw cursor
    int cursor_x = terminal_get_cursor_x(terminal);
    int cursor_y = terminal_get_cursor_y(terminal);
    CGFloat cursor_x_pos = x_offset + (cursor_x * 8.4);
    CGFloat cursor_y_pos = 10 + (cursor_y * 17);
    
    [[[NSColor colorWithRed:0.73 green:0.73 blue:0.73 alpha:0.5] colorWithAlphaComponent:0.5] setStroke];
    NSRect cursor_rect = NSMakeRect(cursor_x_pos, cursor_y_pos, 8.4, 17);
    NSBezierPath *cursor_path = [NSBezierPath bezierPathWithRect:cursor_rect];
    [cursor_path stroke];
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
        
        // Also handle character input for regular keys
        NSString *characters = event.characters;
        if (characters && self.window_data->input_callback) {
            // For printable characters, we can optionally handle them here
            // This is already handled through the key code, but this allows
            // for better character support
        }
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
        window_data->delegate = delegate;
        
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
        
        if (window_data->delegate) {
            [window_data->delegate release];
        }
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

void window_set_renderer(Window* window, Renderer* renderer) {
    if (!window) return;
    
    WindowData *window_data = (WindowData *)window;
    MTKView *metal_view = window_data->metal_view;
    if (metal_view && metal_view.delegate) {
        MTKViewDelegate *delegate = (MTKViewDelegate *)metal_view.delegate;
        delegate.renderer = renderer;
    }
}

void window_set_terminal(Window* window, Terminal* terminal) {
    if (!window) return;
    
    WindowData *window_data = (WindowData *)window;
    window_data->terminal = terminal;
    
    // Create text layer if needed
    if (!window_data->text_layer && window_data->metal_view) {
        CATextLayer *text_layer = [CATextLayer layer];
        text_layer.font = (__bridge CFTypeRef)([NSFont fontWithName:@"Menlo" size:12]);
        text_layer.fontSize = 12;
        text_layer.foregroundColor = CGColorCreateGenericRGB(0, 1, 0, 1);  // Green
        text_layer.backgroundColor = CGColorCreateGenericRGB(0, 0, 0, 1);  // Black
        text_layer.wrapped = YES;
        text_layer.frame = window_data->metal_view.bounds;
        
        [window_data->metal_view.layer addSublayer:text_layer];
        window_data->text_layer = text_layer;
    }
}
