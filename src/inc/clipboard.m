#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#include <stdlib.h>
#include <string.h>
#include "clipboard.h"

typedef struct {
    NSPasteboard *pasteboard;
    char *paste_buffer;
    int paste_buffer_size;
} ClipboardData;

Clipboard* clipboard_create(void) {
    @autoreleasepool {
        ClipboardData *clipboard = (ClipboardData *)malloc(sizeof(ClipboardData));
        if (!clipboard) return NULL;
        
        memset(clipboard, 0, sizeof(ClipboardData));
        
        // Get the general pasteboard (system clipboard)
        clipboard->pasteboard = [NSPasteboard generalPasteboard];
        if (!clipboard->pasteboard) {
            free(clipboard);
            return NULL;
        }
        
        clipboard->paste_buffer = NULL;
        clipboard->paste_buffer_size = 0;
        
        return (Clipboard *)clipboard;
    }
}

void clipboard_destroy(Clipboard* clipboard) {
    if (!clipboard) return;
    
    ClipboardData *clipboard_data = (ClipboardData *)clipboard;
    
    if (clipboard_data->paste_buffer) {
        free(clipboard_data->paste_buffer);
    }
    
    free(clipboard_data);
}

int clipboard_copy(Clipboard* clipboard, const char* text, int length) {
    if (!clipboard || !text || length <= 0) return -1;
    
    @autoreleasepool {
        ClipboardData *clipboard_data = (ClipboardData *)clipboard;
        
        if (!clipboard_data->pasteboard) return -1;
        
        // Create NSString from text
        NSString *ns_text = [[NSString alloc] initWithBytes:text 
                                                    length:length 
                                                  encoding:NSUTF8StringEncoding];
        if (!ns_text) return -1;
        
        // Clear pasteboard and set content
        [clipboard_data->pasteboard clearContents];
        [clipboard_data->pasteboard setString:ns_text forType:NSPasteboardTypeString];
        
        [ns_text release];
        return 0;
    }
}

const char* clipboard_paste(Clipboard* clipboard) {
    if (!clipboard) return NULL;
    
    @autoreleasepool {
        ClipboardData *clipboard_data = (ClipboardData *)clipboard;
        
        if (!clipboard_data->pasteboard) return NULL;
        
        // Get string from pasteboard
        NSString *ns_text = [clipboard_data->pasteboard stringForType:NSPasteboardTypeString];
        if (!ns_text) return NULL;
        
        // Free old buffer if exists
        if (clipboard_data->paste_buffer) {
            free(clipboard_data->paste_buffer);
        }
        
        // Convert to C string
        const char *c_text = [ns_text UTF8String];
        if (!c_text) return NULL;
        
        // Copy to persistent buffer
        clipboard_data->paste_buffer_size = (int)strlen(c_text) + 1;
        clipboard_data->paste_buffer = (char *)malloc(clipboard_data->paste_buffer_size);
        if (!clipboard_data->paste_buffer) return NULL;
        
        strcpy(clipboard_data->paste_buffer, c_text);
        
        return clipboard_data->paste_buffer;
    }
}

int clipboard_has_content(Clipboard* clipboard) {
    if (!clipboard) return 0;
    
    @autoreleasepool {
        ClipboardData *clipboard_data = (ClipboardData *)clipboard;
        
        if (!clipboard_data->pasteboard) return 0;
        
        NSString *ns_text = [clipboard_data->pasteboard stringForType:NSPasteboardTypeString];
        return (ns_text && [ns_text length] > 0) ? 1 : 0;
    }
}
