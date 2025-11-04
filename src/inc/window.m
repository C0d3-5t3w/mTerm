#import <Cocoa/Cocoa.h>
#import <MetalKit/MetalKit.h>
#import <Metal/Metal.h>
#import <QuartzCore/QuartzCore.h>
#import "window.h"
#import "render.h"
#import "terminal.h"
#import "input.h"
#import "shell.h"

// Forward declarations
@class TerminalWindowDelegate;
@class TerminalTextView;

typedef struct {
    NSWindow *ns_window;
    MTKView *metal_view;
    TerminalWindowDelegate *delegate;
    CATextLayer *text_layer;
    TerminalTextView *text_view;
    Terminal *terminal;
    Shell *shell;
    int should_close;
    int initialized;
    InputCallback input_callback;
    void *input_context;
} WindowData;

@interface TerminalTextView : NSView
@property (nonatomic, assign) WindowData *window_data;
@property (nonatomic, strong) NSFont *terminal_font;
@end

@implementation TerminalTextView

- (BOOL)acceptsFirstResponder {
    return YES;
}

- (void)keyDown:(NSEvent *)event {
    if (self.window_data && self.window_data->input_callback) {
        unsigned short key_code = event.keyCode;
        
        // Handle the key code for special keys
        self.window_data->input_callback(
            self.window_data->input_context,
            (int)key_code,
            0  // ACTION_PRESSED
        );
    }
    // Don't call super to prevent beep on unhandled keys
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
}

- (void)drawRect:(NSRect)dirtyRect {
    if (!self.window_data || !self.window_data->terminal) {
        [[NSColor blackColor] setFill];
        NSRectFill(self.bounds);
        return;
    }
    
    Terminal *terminal = self.window_data->terminal;
    const char *text = terminal_get_text(terminal);
    if (!text) {
        [[NSColor blackColor] setFill];
        NSRectFill(self.bounds);
        return;
    }
    
    // Setup font once
    if (!self.terminal_font) {
        self.terminal_font = [NSFont fontWithName:@"Menlo" size:12.0];
        if (!self.terminal_font) {
            self.terminal_font = [NSFont fontWithName:@"Monaco" size:12.0];
        }
        if (!self.terminal_font) {
            self.terminal_font = [NSFont fontWithName:@"Courier New" size:12.0];
        }
        if (!self.terminal_font) {
            self.terminal_font = [NSFont systemFontOfSize:12.0];
        }
    }
    
    // Draw black background
    [[NSColor blackColor] setFill];
    NSRectFill(self.bounds);
    
    // Create text attributes for terminal text
    NSDictionary *attrs = @{
        NSFontAttributeName: self.terminal_font,
        NSForegroundColorAttributeName: [NSColor colorWithRed:0.73 green:0.73 blue:0.73 alpha:1.0]
    };
    
    NSRect bounds = self.bounds;
    
    // Calculate character dimensions
    NSString *testChar = @"M";
    NSSize charSize = [testChar sizeWithAttributes:attrs];
    CGFloat char_width = charSize.width;
    CGFloat line_height = charSize.height;
    
    // Offsets for drawing
    CGFloat x_offset = 6.0;
    CGFloat y_offset_top = 6.0;
    
    // Get current terminal dimensions
    int term_width = terminal_get_width(terminal);
    int term_height = terminal_get_height(terminal);
    
    // Get terminal cursor position
    int cursor_x = terminal_get_cursor_x(terminal);
    int cursor_y = terminal_get_cursor_y(terminal);
    
    // Draw text in a grid pattern
    CGFloat y_offset = bounds.size.height - y_offset_top - line_height;  // Start from top
    
    // Draw each row of the terminal buffer
    const char *buffer = text;
    for (int row = 0; row < term_height; row++) {
        // Extract line from buffer (term_width chars per row)
        char *line_buffer = (char *)malloc(term_width + 1);
        if (!line_buffer) continue;
        
        int start_pos = row * term_width;
        strncpy(line_buffer, buffer + start_pos, term_width);
        line_buffer[term_width] = '\0';
        
        // Create NSString and draw
        NSString *line = [NSString stringWithUTF8String:line_buffer];
        if (line) {
            // Draw the line of text
            [line drawAtPoint:CGPointMake(x_offset, y_offset) withAttributes:attrs];
        }
        
        free(line_buffer);
        
        // Draw cursor if on this row
        if (row == cursor_y && cursor_x < term_width) {
            CGRect cursor_rect = CGRectMake(
                x_offset + (cursor_x * char_width),
                y_offset,
                char_width,
                line_height
            );
            [[NSColor colorWithRed:0.73 green:0.73 blue:0.73 alpha:0.7] setStroke];
            [NSBezierPath strokeRect:cursor_rect];
        }
        
        y_offset -= line_height;
    }
}
@end

@interface MTKViewDelegate : NSObject<MTKViewDelegate>
@property (nonatomic, assign) WindowData *window_data;
@property (nonatomic, assign) Renderer *renderer;
@end

@implementation MTKViewDelegate
- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
}

- (void)drawInMTKView:(MTKView *)view {
    // This is called automatically by MTKView on each frame
    // Just clear to black - terminal content is drawn by TerminalTextView
    if (self.renderer) {
        renderer_clear(self.renderer, 0.0f, 0.0f, 0.0f, 1.0f);
    }
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

- (void)windowDidResize:(NSNotification *)notification {
    // Don't resize until everything is initialized
    if (!self.window_data || !self.window_data->initialized) return;
    
    if (self.window_data->text_view && self.window_data->terminal && self.window_data->shell) {
        // Calculate new terminal dimensions
        TerminalTextView *textView = self.window_data->text_view;
        NSRect bounds = textView.bounds;
        
        // Use same font metrics as drawRect
        NSFont *font = [NSFont fontWithName:@"Menlo" size:12.0];
        if (!font) font = [NSFont systemFontOfSize:12.0];
        
        NSDictionary *attrs = @{NSFontAttributeName: font};
        NSString *testChar = @"M";
        NSSize charSize = [testChar sizeWithAttributes:attrs];
        CGFloat char_width = charSize.width;
        CGFloat line_height = charSize.height;
        
        CGFloat x_offset = 6.0;
        CGFloat y_offset_top = 6.0;
        int new_width = (int)((bounds.size.width - x_offset * 2) / char_width);
        int new_height = (int)((bounds.size.height - y_offset_top * 2) / line_height);
        
        // Ensure minimum size
        if (new_width < 20) new_width = 20;
        if (new_height < 5) new_height = 5;
        
        // Get current dimensions
        int current_width = terminal_get_width(self.window_data->terminal);
        int current_height = terminal_get_height(self.window_data->terminal);
        
        // Only resize if dimensions changed significantly (avoid tiny fluctuations)
        if (abs(current_width - new_width) > 1 || abs(current_height - new_height) > 1) {
            NSLog(@"Resizing terminal from %dx%d to %dx%d", current_width, current_height, new_width, new_height);
            terminal_resize(self.window_data->terminal, new_width, new_height);
            shell_resize_pty(self.window_data->shell, new_width, new_height);
        }
        
        // Force text view to recalculate and redraw with new dimensions
        [self.window_data->text_view setNeedsDisplay:YES];
    }
}
@end

@interface TerminalView : MTKView
@property (nonatomic, assign) WindowData *window_data;
@end

@implementation TerminalView

- (BOOL)acceptsFirstResponder {
    return YES;
}

- (BOOL)canBecomeKeyView {
    return YES;
}

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
        
        // Create TerminalTextView for drawing terminal content
        TerminalTextView *text_view = [[TerminalTextView alloc] initWithFrame:NSMakeRect(0, 0, width, height)];
        if (!text_view) {
            [ns_window release];
            free(window_data);
            return NULL;
        }
        
        text_view.window_data = window_data;
        text_view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        [ns_window.contentView addSubview:text_view];
        
        window_data->text_view = text_view;
        
        // Also create an invisible MTKView for Metal rendering if needed in the future
        MTKView *metal_view = [[TerminalView alloc] initWithFrame:NSMakeRect(0, 0, width, height)];
        if (!metal_view) {
            [text_view release];
            [ns_window release];
            free(window_data);
            return NULL;
        }
        
        ((TerminalView *)metal_view).window_data = window_data;
        
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        if (!device) {
            [metal_view release];
            [text_view release];
            [ns_window release];
            free(window_data);
            return NULL;
        }
        
        metal_view.device = device;
        metal_view.drawableSize = CGSizeMake(width, height);
        metal_view.delegate = [[MTKViewDelegate alloc] init];
        ((MTKViewDelegate *)metal_view.delegate).window_data = window_data;
        metal_view.hidden = YES;  // Hide Metal view since we're using text view for now
        metal_view.paused = YES;  // Don't run the Metal render loop
        [ns_window.contentView addSubview:metal_view positioned:NSWindowBelow relativeTo:text_view];
        
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
            
            // Make the text view first responder so it can receive keyboard input
            if (window_data->text_view) {
                [window_data->ns_window makeFirstResponder:window_data->text_view];
            }
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
    
    // Trigger initial redraw
    if (window_data->text_view) {
        [window_data->text_view setNeedsDisplay:YES];
    }
    
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

void window_set_shell(Window* window, Shell* shell) {
    if (!window) return;
    
    WindowData *window_data = (WindowData *)window;
    window_data->shell = shell;
}

void window_mark_initialized(Window* window) {
    if (!window) return;
    
    WindowData *window_data = (WindowData *)window;
    window_data->initialized = 1;
}

void window_refresh(Window* window) {
    if (!window) return;
    
    @autoreleasepool {
        WindowData *window_data = (WindowData *)window;
        
        // Redraw the text view
        if (window_data->text_view) {
            [window_data->text_view setNeedsDisplay:YES];
            [window_data->text_view displayIfNeeded];
        }
    }
}
