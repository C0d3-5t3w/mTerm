#ifndef CLIPBOARD_H
#define CLIPBOARD_H

typedef struct Clipboard Clipboard;

// Clipboard creation and management
Clipboard* clipboard_create(void);
void clipboard_destroy(Clipboard* clipboard);

// Copy/Paste operations
int clipboard_copy(Clipboard* clipboard, const char* text, int length);
const char* clipboard_paste(Clipboard* clipboard);

// Query clipboard state
int clipboard_has_content(Clipboard* clipboard);

#endif // CLIPBOARD_H
