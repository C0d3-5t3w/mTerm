#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include "search.h"
#include "terminal.h"
#include "scrollback.h"

#define SEARCH_QUERY_MAX 256
#define MAX_RESULTS 100

typedef struct {
    Terminal *terminal;
    Scrollback *scrollback;
    char query[SEARCH_QUERY_MAX];
    int case_sensitive;
    int results[MAX_RESULTS];  // Line indices of results
    int result_count;
    int current_result_index;
} SearchData;

// Case-sensitive string search
static int str_search_sensitive(const char *haystack, const char *needle) {
    if (!haystack || !needle) return -1;
    
    const char *h = haystack;
    while (*h) {
        const char *n = needle;
        const char *h_tmp = h;
        
        while (*n && *h_tmp == *n) {
            h_tmp++;
            n++;
        }
        
        if (!*n) {
            return (int)(h - haystack);
        }
        
        h++;
    }
    
    return -1;
}

// Case-insensitive string search
static int str_search_insensitive(const char *haystack, const char *needle) {
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
            return (int)(h - haystack);
        }
        
        h++;
    }
    
    return -1;
}

Search* search_create(Terminal* terminal, Scrollback* scrollback) {
    SearchData *search = (SearchData *)malloc(sizeof(SearchData));
    if (!search) return NULL;
    
    memset(search, 0, sizeof(SearchData));
    
    search->terminal = terminal;
    search->scrollback = scrollback;
    search->case_sensitive = 0;  // Case-insensitive by default
    search->result_count = 0;
    search->current_result_index = -1;
    
    return (Search *)search;
}

void search_destroy(Search* search) {
    if (!search) return;
    free(search);
}

int search_find(Search* search, const char* query) {
    if (!search || !query || !*query) return -1;
    
    SearchData *search_data = (SearchData *)search;
    
    // Store query
    strncpy(search_data->query, query, SEARCH_QUERY_MAX - 1);
    search_data->query[SEARCH_QUERY_MAX - 1] = '\0';
    
    // Clear previous results
    search_data->result_count = 0;
    search_data->current_result_index = -1;
    
    // Function pointer for search based on case sensitivity
    int (*search_func)(const char *, const char *) = 
        search_data->case_sensitive ? str_search_sensitive : str_search_insensitive;
    
    // Search in terminal buffer
    if (search_data->terminal) {
        const char *terminal_text = terminal_get_text(search_data->terminal);
        if (terminal_text && search_func(terminal_text, query) >= 0) {
            // Found in current terminal
            if (search_data->result_count < MAX_RESULTS) {
                search_data->results[search_data->result_count++] = -1;  // -1 = current terminal
            }
        }
    }
    
    // Search in scrollback
    if (search_data->scrollback) {
        int line_count = scrollback_get_line_count(search_data->scrollback);
        for (int i = 0; i < line_count && search_data->result_count < MAX_RESULTS; i++) {
            const char *line = scrollback_get_line(search_data->scrollback, i);
            if (line && search_func(line, query) >= 0) {
                search_data->results[search_data->result_count++] = i;
            }
        }
    }
    
    if (search_data->result_count > 0) {
        search_data->current_result_index = 0;
        return search_data->results[0];
    }
    
    return -1;  // Not found
}

int search_find_next(Search* search) {
    if (!search) return -1;
    
    SearchData *search_data = (SearchData *)search;
    
    if (search_data->result_count <= 0) {
        return -1;
    }
    
    if (search_data->current_result_index < 0) {
        search_data->current_result_index = 0;
    } else {
        search_data->current_result_index = 
            (search_data->current_result_index + 1) % search_data->result_count;
    }
    
    return search_data->results[search_data->current_result_index];
}

int search_find_prev(Search* search) {
    if (!search) return -1;
    
    SearchData *search_data = (SearchData *)search;
    
    if (search_data->result_count <= 0) {
        return -1;
    }
    
    if (search_data->current_result_index < 0) {
        search_data->current_result_index = search_data->result_count - 1;
    } else {
        search_data->current_result_index = 
            (search_data->current_result_index - 1 + search_data->result_count) % search_data->result_count;
    }
    
    return search_data->results[search_data->current_result_index];
}

void search_clear(Search* search) {
    if (!search) return;
    
    SearchData *search_data = (SearchData *)search;
    
    memset(search_data->query, 0, SEARCH_QUERY_MAX);
    search_data->result_count = 0;
    search_data->current_result_index = -1;
}

void search_set_query(Search* search, const char* query) {
    if (!search || !query) return;
    
    SearchData *search_data = (SearchData *)search;
    strncpy(search_data->query, query, SEARCH_QUERY_MAX - 1);
    search_data->query[SEARCH_QUERY_MAX - 1] = '\0';
}

const char* search_get_query(Search* search) {
    if (!search) return NULL;
    
    SearchData *search_data = (SearchData *)search;
    return search_data->query;
}

int search_get_result_line(Search* search) {
    if (!search) return -1;
    
    SearchData *search_data = (SearchData *)search;
    
    if (search_data->current_result_index < 0 || search_data->current_result_index >= search_data->result_count) {
        return -1;
    }
    
    return search_data->results[search_data->current_result_index];
}

int search_get_result_column(Search* search) {
    if (!search) return -1;
    
    SearchData *search_data = (SearchData *)search;
    
    int line_index = search_get_result_line(search);
    if (line_index < 0) return -1;
    
    const char *line = NULL;
    if (line_index == -1 && search_data->terminal) {
        line = terminal_get_text(search_data->terminal);
    } else if (line_index >= 0 && search_data->scrollback) {
        line = scrollback_get_line(search_data->scrollback, line_index);
    }
    
    if (!line || !*search_data->query) return -1;
    
    int (*search_func)(const char *, const char *) = 
        search_data->case_sensitive ? str_search_sensitive : str_search_insensitive;
    
    return search_func(line, search_data->query);
}

int search_get_results_count(Search* search) {
    if (!search) return 0;
    
    SearchData *search_data = (SearchData *)search;
    return search_data->result_count;
}

void search_set_case_sensitive(Search* search, int case_sensitive) {
    if (!search) return;
    
    SearchData *search_data = (SearchData *)search;
    search_data->case_sensitive = case_sensitive;
}

int search_get_case_sensitive(Search* search) {
    if (!search) return 0;
    
    SearchData *search_data = (SearchData *)search;
    return search_data->case_sensitive;
}
