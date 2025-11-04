#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#import <Cocoa/Cocoa.h>
#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <QuartzCore/CAMetalLayer.h>
#import <simd/simd.h>

#import "inc/window.h"
#import "inc/render.h"
#import "inc/shell.h"
#import "inc/input.h"
#import "inc/terminal.h"

#define WINDOW_WIDTH 1200
#define WINDOW_HEIGHT 800

// Global variables for the application state
static Window *g_window = NULL;
static Renderer *g_renderer = NULL;
static Shell *g_shell = NULL;
static InputHandler *g_input = NULL;
static Terminal *g_terminal = NULL;

// Input callback for keyboard events
void on_key_input(void* context, int key, int action) {
    if (g_input) {
        input_handle_key(g_input, key, action);
        
        // If Return key pressed and we have input, send it to the shell
        if (key == KEY_RETURN && action == ACTION_PRESSED && g_shell) {
            const char *text = input_get_text_input(g_input);
            if (text) {
                shell_write_input(g_shell, text, strlen(text));
                input_clear_buffer(g_input);
            }
        }
    }
}

// Application delegate to handle rendering and shell updates
@interface AppDelegate : NSObject <NSApplicationDelegate>
@end

@implementation AppDelegate
- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    // Start the render/update loop
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:(1.0 / 60.0)
                                                      target:self
                                                    selector:@selector(update:)
                                                    userInfo:nil
                                                     repeats:YES];
}

- (void)update:(NSTimer *)timer {
    char buffer[4096];
    int bytes_read;
    
    @autoreleasepool {
        // Read shell output
        if (g_shell && shell_is_running(g_shell)) {
            bytes_read = shell_read_output(g_shell, buffer, sizeof(buffer) - 1);
            if (bytes_read > 0) {
                buffer[bytes_read] = '\0';
                // Write to terminal buffer instead of stdout
                if (g_terminal) {
                    terminal_write(g_terminal, buffer, bytes_read);
                }
            }
        }
        
        // MTKView will handle rendering through its delegate
    }
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)app {
    return YES;
}
@end

int main() {
    @autoreleasepool {
        // Create application
        NSApplication *app = [NSApplication sharedApplication];
        
        // Create and set the app delegate
        AppDelegate *delegate = [[AppDelegate alloc] init];
        [app setDelegate:delegate];
        
        [app setActivationPolicy:NSApplicationActivationPolicyRegular];
        
        // Create window
        g_window = window_create("mTerm - macOS Terminal", WINDOW_WIDTH, WINDOW_HEIGHT);
        if (!g_window) {
            fprintf(stderr, "Failed to create window\n");
            return 1;
        }
        
        // Set up input callback
        window_set_key_callback(g_window, on_key_input, NULL);
        
        // Get Metal view
        MTKView *metal_view = window_get_metal_view(g_window);
        if (!metal_view) {
            fprintf(stderr, "Failed to get Metal view\n");
            window_destroy(g_window);
            return 1;
        }
        
        // Create renderer
        g_renderer = renderer_create(metal_view);
        if (!g_renderer) {
            fprintf(stderr, "Failed to create renderer\n");
            window_destroy(g_window);
            return 1;
        }
        
        // Set renderer on the window so MTKViewDelegate can use it
        window_set_renderer(g_window, g_renderer);
        
        // Create terminal buffer
        g_terminal = terminal_create(120, 50);
        if (!g_terminal) {
            fprintf(stderr, "Failed to create terminal\n");
            renderer_destroy(g_renderer);
            window_destroy(g_window);
            return 1;
        }
        
        // Add test welcome message to terminal
        const char *welcome = "Welcome to mTerm - macOS Terminal Emulator\n";
        terminal_write(g_terminal, welcome, strlen(welcome));
        terminal_write(g_terminal, "\n", 1);
        
        // Set terminal on renderer so it can display it
        renderer_set_terminal(g_renderer, g_terminal);
        
        // Create shell
        g_shell = shell_create();
        if (!g_shell) {
            fprintf(stderr, "Failed to create shell\n");
            renderer_destroy(g_renderer);
            window_destroy(g_window);
            return 1;
        }
        
        // Initialize PTY
        if (shell_init_pty(g_shell) < 0) {
            fprintf(stderr, "Failed to initialize shell PTY\n");
            shell_destroy(g_shell);
            renderer_destroy(g_renderer);
            window_destroy(g_window);
            return 1;
        }
        
        // Create input handler
        g_input = input_create();
        if (!g_input) {
            fprintf(stderr, "Failed to create input handler\n");
            shell_destroy(g_shell);
            renderer_destroy(g_renderer);
            window_destroy(g_window);
            return 1;
        }
        
        // Show window
        window_show(g_window);
        
        // Make the app key and front
        [app activateIgnoringOtherApps:YES];
        
        // Create menu bar
        NSMenu *mainMenu = [[NSMenu new] autorelease];
        NSMenuItem *appMenuItem = [[NSMenuItem new] autorelease];
        [mainMenu addItem:appMenuItem];
        [app setMainMenu:mainMenu];
        
        NSMenu *appMenu = [[NSMenu new] autorelease];
        NSMenuItem *quitMenuItem = [[[NSMenuItem alloc]
            initWithTitle:@"Quit mTerm"
            action:@selector(terminate:)
            keyEquivalent:@"q"] autorelease];
        [appMenu addItem:quitMenuItem];
        [appMenuItem setSubmenu:appMenu];
        
        // Use the application's built-in run loop
        // The update timer will handle rendering
        // Window close is handled by applicationShouldTerminateAfterLastWindowClosed:
        [app run];
        
        // Cleanup
        if (g_input) {
            input_destroy(g_input);
        }
        if (g_shell) {
            shell_destroy(g_shell);
        }
        if (g_terminal) {
            terminal_destroy(g_terminal);
        }
        if (g_renderer) {
            renderer_destroy(g_renderer);
        }
        if (g_window) {
            window_destroy(g_window);
        }
        
        [delegate release];
        
        return 0;
    }
}
