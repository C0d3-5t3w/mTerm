#ifndef SCROLLBACK_H
#define SCROLLBACK_H

typedef struct Scrollback Scrollback;

// Scrollback creation and management
Scrollback* scrollback_create(int max_lines);
void scrollback_destroy(Scrollback* scrollback);

// Buffer management
void scrollback_add_line(Scrollback* scrollback, const char* line);
void scrollback_clear(Scrollback* scrollback);

// Access scrollback
const char* scrollback_get_line(Scrollback* scrollback, int line_index);
int scrollback_get_line_count(Scrollback* scrollback);
int scrollback_get_max_lines(Scrollback* scrollback);

// Search functionality
int scrollback_search(Scrollback* scrollback, const char* query, int start_from, int search_backward);
int scrollback_search_next(Scrollback* scrollback);
int scrollback_search_prev(Scrollback* scrollback);

#endif // SCROLLBACK_H
