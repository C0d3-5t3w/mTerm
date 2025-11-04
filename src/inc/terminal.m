#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#import "terminal.h"

typedef struct {
    char *buffer;
    int width;
    int height;
    int cursor_x;
    int cursor_y;
    int scroll_pos;
    int buffer_size;
} TerminalData;

Terminal* terminal_create(int width, int height) {
    TerminalData *term = (TerminalData *)malloc(sizeof(TerminalData));
    if (!term) return NULL;
    
    memset(term, 0, sizeof(TerminalData));
    term->width = width;
    term->height = height;
    term->buffer_size = width * height;
    
    // Allocate dynamic buffer
    term->buffer = (char *)malloc(term->buffer_size);
    if (!term->buffer) {
        free(term);
        return NULL;
    }
    
    // Fill buffer with spaces
    memset(term->buffer, ' ', term->buffer_size);
    
    return (Terminal *)term;
}

void terminal_destroy(Terminal* terminal) {
    if (!terminal) return;
    TerminalData *term = (TerminalData *)terminal;
    if (term->buffer) {
        free(term->buffer);
    }
    free(terminal);
}

void terminal_write(Terminal* terminal, const char* data, int length) {
    if (!terminal || !data || length <= 0) return;
    
    TerminalData *term = (TerminalData *)terminal;
    
    for (int i = 0; i < length; i++) {
        char c = data[i];
        
        if (c == '\n') {
            // Newline - move to next line
            term->cursor_x = 0;
            term->cursor_y++;
            
            // Scroll if needed
            if (term->cursor_y >= term->height) {
                // Scroll up by one line
                memmove(term->buffer, term->buffer + term->width, 
                        term->width * (term->height - 1));
                memset(term->buffer + term->width * (term->height - 1), ' ', term->width);
                term->cursor_y = term->height - 1;
            }
        } else if (c == '\r') {
            // Carriage return
            term->cursor_x = 0;
        } else if (c == '\t') {
            // Tab - advance to next tab stop (every 8 spaces for xterm compatibility)
            term->cursor_x = ((term->cursor_x / 8) + 1) * 8;
            if (term->cursor_x >= term->width) {
                term->cursor_x = 0;
                term->cursor_y++;
                if (term->cursor_y >= term->height) {
                    memmove(term->buffer, term->buffer + term->width, 
                            term->width * (term->height - 1));
                    memset(term->buffer + term->width * (term->height - 1), ' ', term->width);
                    term->cursor_y = term->height - 1;
                }
            }
        } else if (c == '\b' || c == 127) {
            // Backspace or DEL
            if (term->cursor_x > 0) {
                term->cursor_x--;
                int pos = term->cursor_y * term->width + term->cursor_x;
                term->buffer[pos] = ' ';
            }
        } else if (c == '\033' || c == 27) {
            // Escape sequence - handle common xterm sequences
            if (i + 1 < length && data[i + 1] == '[') {
                // CSI sequence: ESC [ ... command
                i += 2;
                int param = 0;
                
                // Parse numeric parameter
                while (i < length && isdigit(data[i])) {
                    param = param * 10 + (data[i] - '0');
                    i++;
                }
                
                // Skip any additional parameters or modifiers
                while (i < length && (data[i] == ';' || data[i] == '?' || isdigit(data[i]))) {
                    if (data[i] == ';') {
                        // Skip to next parameter
                        i++;
                        while (i < length && isdigit(data[i])) i++;
                    } else {
                        i++;
                    }
                }
                
                // Process command
                if (i < length) {
                    char cmd = data[i];
                    switch (cmd) {
                        case 'H':  // Cursor home/move
                        case 'f':
                            term->cursor_x = 0;
                            term->cursor_y = 0;
                            break;
                        case 'A':  // Cursor up
                            if (param == 0) param = 1;
                            term->cursor_y = (term->cursor_y - param < 0) ? 0 : term->cursor_y - param;
                            break;
                        case 'B':  // Cursor down
                            if (param == 0) param = 1;
                            term->cursor_y = (term->cursor_y + param >= term->height) ? term->height - 1 : term->cursor_y + param;
                            break;
                        case 'C':  // Cursor forward (right)
                            if (param == 0) param = 1;
                            term->cursor_x = (term->cursor_x + param >= term->width) ? term->width - 1 : term->cursor_x + param;
                            break;
                        case 'D':  // Cursor backward (left)
                            if (param == 0) param = 1;
                            term->cursor_x = (term->cursor_x - param < 0) ? 0 : term->cursor_x - param;
                            break;
                        case 'J':  // Clear display
                            if (param == 2) {
                                memset(term->buffer, ' ', term->buffer_size);
                                term->cursor_x = 0;
                                term->cursor_y = 0;
                            }
                            break;
                        case 'K':  // Clear line
                            if (param == 0) {
                                // Clear from cursor to end of line
                                int pos = term->cursor_y * term->width + term->cursor_x;
                                memset(term->buffer + pos, ' ', term->width - term->cursor_x);
                            }
                            break;
                        case 'm':  // Set graphics mode (colors, bold, etc.)
                            // For now, just skip - we'll add color support later
                            break;
                        default:
                            break;
                    }
                }
            } else {
                // Single escape character or unknown sequence
                i++;
            }
        } else if (isprint(c)) {
            // Printable character
            int pos = term->cursor_y * term->width + term->cursor_x;
            if (pos < (int)sizeof(term->buffer)) {
                term->buffer[pos] = c;
            }
            
            term->cursor_x++;
            if (term->cursor_x >= term->width) {
                term->cursor_x = 0;
                term->cursor_y++;
                
                // Scroll if needed
                if (term->cursor_y >= term->height) {
                    memmove(term->buffer, term->buffer + term->width, 
                            term->width * (term->height - 1));
                    memset(term->buffer + term->width * (term->height - 1), ' ', term->width);
                    term->cursor_y = term->height - 1;
                }
            }
        }
    }
}

const char* terminal_get_text(Terminal* terminal) {
    if (!terminal) return NULL;
    TerminalData *term = (TerminalData *)terminal;
    return term->buffer;
}

int terminal_get_cursor_x(Terminal* terminal) {
    if (!terminal) return 0;
    TerminalData *term = (TerminalData *)terminal;
    return term->cursor_x;
}

int terminal_get_cursor_y(Terminal* terminal) {
    if (!terminal) return 0;
    TerminalData *term = (TerminalData *)terminal;
    return term->cursor_y;
}

void terminal_clear(Terminal* terminal) {
    if (!terminal) return;
    TerminalData *term = (TerminalData *)terminal;
    memset(term->buffer, ' ', term->buffer_size);
    term->cursor_x = 0;
    term->cursor_y = 0;
}

int terminal_get_width(Terminal* terminal) {
    if (!terminal) return 0;
    TerminalData *term = (TerminalData *)terminal;
    return term->width;
}

int terminal_get_height(Terminal* terminal) {
    if (!terminal) return 0;
    TerminalData *term = (TerminalData *)terminal;
    return term->height;
}

void terminal_resize(Terminal* terminal, int width, int height) {
    if (!terminal || width <= 0 || height <= 0) return;
    
    TerminalData *term = (TerminalData *)terminal;
    
    // Calculate new buffer size
    int new_buffer_size = width * height;
    
    // Allocate new buffer
    char *new_buffer = (char *)malloc(new_buffer_size);
    if (!new_buffer) return;
    
    // Fill new buffer with spaces
    memset(new_buffer, ' ', new_buffer_size);
    
    // Copy old content to new buffer (as much as fits)
    int copy_rows = (term->height < height) ? term->height : height;
    int copy_cols = (term->width < width) ? term->width : width;
    
    for (int row = 0; row < copy_rows; row++) {
        memcpy(new_buffer + row * width,
               term->buffer + row * term->width,
               copy_cols);
    }
    
    // Free old buffer and update
    free(term->buffer);
    term->buffer = new_buffer;
    term->width = width;
    term->height = height;
    term->buffer_size = new_buffer_size;
    
    // Adjust cursor position if needed
    if (term->cursor_x >= width) term->cursor_x = width - 1;
    if (term->cursor_y >= height) term->cursor_y = height - 1;
}
