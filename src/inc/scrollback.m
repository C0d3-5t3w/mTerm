#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <ctype.h>
#include "scrollback.h"

#define DEFAULT_MAX_LINES 10000
#define LINE_MAX_LENGTH 4096

typedef struct {
    char **lines;
    int *line_lengths;
    int line_count;
    int max_lines;
    int current_index;
    char *search_query;
    int last_search_index;
} ScrollbackData;

Scrollback* scrollback_create(int max_lines) {
    ScrollbackData *scrollback = (ScrollbackData *)malloc(sizeof(ScrollbackData));
    if (!scrollback) return NULL;
    
    memset(scrollback, 0, sizeof(ScrollbackData));
    
    scrollback->max_lines = (max_lines > 0) ? max_lines : DEFAULT_MAX_LINES;
    scrollback->lines = (char **)malloc(sizeof(char *) * scrollback->max_lines);
    scrollback->line_lengths = (int *)malloc(sizeof(int) * scrollback->max_lines);
    
    if (!scrollback->lines || !scrollback->line_lengths) {
        if (scrollback->lines) free(scrollback->lines);
        if (scrollback->line_lengths) free(scrollback->line_lengths);
        free(scrollback);
        return NULL;
    }
    
    memset(scrollback->lines, 0, sizeof(char *) * scrollback->max_lines);
    memset(scrollback->line_lengths, 0, sizeof(int) * scrollback->max_lines);
    
    scrollback->search_query = NULL;
    scrollback->line_count = 0;
    scrollback->current_index = 0;
    scrollback->last_search_index = -1;
    
    return (Scrollback *)scrollback;
}

void scrollback_destroy(Scrollback* scrollback) {
    if (!scrollback) return;
    
    ScrollbackData *scrollback_data = (ScrollbackData *)scrollback;
    
    for (int i = 0; i < scrollback_data->max_lines; i++) {
        if (scrollback_data->lines[i]) {
            free(scrollback_data->lines[i]);
        }
    }
    
    free(scrollback_data->lines);
    free(scrollback_data->line_lengths);
    
    if (scrollback_data->search_query) {
        free(scrollback_data->search_query);
    }
    
    free(scrollback_data);
}

void scrollback_add_line(Scrollback* scrollback, const char* line) {
    if (!scrollback || !line) return;
    
    ScrollbackData *scrollback_data = (ScrollbackData *)scrollback;
    
    int line_len = (int)strlen(line);
    if (line_len > LINE_MAX_LENGTH) {
        line_len = LINE_MAX_LENGTH;
    }
    
    // If buffer is full, shift all lines
    if (scrollback_data->line_count >= scrollback_data->max_lines) {
        // Free the oldest line
        if (scrollback_data->lines[0]) {
            free(scrollback_data->lines[0]);
        }
        
        // Shift all lines down
        for (int i = 0; i < scrollback_data->max_lines - 1; i++) {
            scrollback_data->lines[i] = scrollback_data->lines[i + 1];
            scrollback_data->line_lengths[i] = scrollback_data->line_lengths[i + 1];
        }
        
        scrollback_data->current_index = scrollback_data->max_lines - 1;
    } else {
        scrollback_data->current_index = scrollback_data->line_count;
        scrollback_data->line_count++;
    }
    
    // Add new line
    scrollback_data->lines[scrollback_data->current_index] = (char *)malloc(line_len + 1);
    if (scrollback_data->lines[scrollback_data->current_index]) {
        strncpy(scrollback_data->lines[scrollback_data->current_index], line, line_len);
        scrollback_data->lines[scrollback_data->current_index][line_len] = '\0';
        scrollback_data->line_lengths[scrollback_data->current_index] = line_len;
    }
}

void scrollback_clear(Scrollback* scrollback) {
    if (!scrollback) return;
    
    ScrollbackData *scrollback_data = (ScrollbackData *)scrollback;
    
    for (int i = 0; i < scrollback_data->max_lines; i++) {
        if (scrollback_data->lines[i]) {
            free(scrollback_data->lines[i]);
            scrollback_data->lines[i] = NULL;
        }
        scrollback_data->line_lengths[i] = 0;
    }
    
    scrollback_data->line_count = 0;
    scrollback_data->current_index = 0;
}

const char* scrollback_get_line(Scrollback* scrollback, int line_index) {
    if (!scrollback || line_index < 0) return NULL;
    
    ScrollbackData *scrollback_data = (ScrollbackData *)scrollback;
    
    if (line_index >= scrollback_data->line_count) {
        return NULL;
    }
    
    return scrollback_data->lines[line_index];
}

int scrollback_get_line_count(Scrollback* scrollback) {
    if (!scrollback) return 0;
    
    ScrollbackData *scrollback_data = (ScrollbackData *)scrollback;
    return scrollback_data->line_count;
}

int scrollback_get_max_lines(Scrollback* scrollback) {
    if (!scrollback) return 0;
    
    ScrollbackData *scrollback_data = (ScrollbackData *)scrollback;
    return scrollback_data->max_lines;
}

// Case-insensitive string search helper
static int str_search_case_insensitive(const char *haystack, const char *needle) {
    if (!haystack || !needle) return -1;
    
    const char *h = haystack;
    while (*h) {
        const char *n = needle;
        const char *h_tmp = h;
        
        while (*n && tolower((unsigned char)*h_tmp) == tolower((unsigned char)*n)) {
            h_tmp++;
            n++;
        }
        
        if (!*n) {
            return (int)(h - haystack);  // Found at this position
        }
        
        h++;
    }
    
    return -1;  // Not found
}

int scrollback_search(Scrollback* scrollback, const char* query, int start_from, int search_backward) {
    if (!scrollback || !query || !*query) return -1;
    
    ScrollbackData *scrollback_data = (ScrollbackData *)scrollback;
    
    // Update search query
    if (scrollback_data->search_query) {
        free(scrollback_data->search_query);
    }
    scrollback_data->search_query = (char *)malloc(strlen(query) + 1);
    if (!scrollback_data->search_query) return -1;
    strcpy(scrollback_data->search_query, query);
    
    scrollback_data->last_search_index = -1;
    
    // Search through lines
    if (search_backward) {
        // Search from start_from backwards
        for (int i = start_from; i >= 0; i--) {
            if (scrollback_data->lines[i] && 
                str_search_case_insensitive(scrollback_data->lines[i], query) >= 0) {
                scrollback_data->last_search_index = i;
                return i;
            }
        }
    } else {
        // Search from start_from forwards
        for (int i = start_from; i < scrollback_data->line_count; i++) {
            if (scrollback_data->lines[i] && 
                str_search_case_insensitive(scrollback_data->lines[i], query) >= 0) {
                scrollback_data->last_search_index = i;
                return i;
            }
        }
    }
    
    return -1;  // Not found
}

int scrollback_search_next(Scrollback* scrollback) {
    if (!scrollback) return -1;
    
    ScrollbackData *scrollback_data = (ScrollbackData *)scrollback;
    
    if (!scrollback_data->search_query) return -1;
    
    int start_from = (scrollback_data->last_search_index >= 0) ? 
                     scrollback_data->last_search_index + 1 : 0;
    
    return scrollback_search(scrollback, scrollback_data->search_query, start_from, 0);
}

int scrollback_search_prev(Scrollback* scrollback) {
    if (!scrollback) return -1;
    
    ScrollbackData *scrollback_data = (ScrollbackData *)scrollback;
    
    if (!scrollback_data->search_query) return -1;
    
    int start_from = (scrollback_data->last_search_index > 0) ? 
                     scrollback_data->last_search_index - 1 : 
                     scrollback_data->line_count - 1;
    
    return scrollback_search(scrollback, scrollback_data->search_query, start_from, 1);
}
