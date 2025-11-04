#ifndef TERMINAL_H
#define TERMINAL_H

typedef struct Terminal Terminal;

// Terminal creation and management
Terminal* terminal_create(int width, int height);
void terminal_destroy(Terminal* terminal);

// Write data to terminal
void terminal_write(Terminal* terminal, const char* data, int length);

// Get buffer for rendering
const char* terminal_get_text(Terminal* terminal);
int terminal_get_cursor_x(Terminal* terminal);
int terminal_get_cursor_y(Terminal* terminal);

// Clear terminal
void terminal_clear(Terminal* terminal);

#endif // TERMINAL_H
