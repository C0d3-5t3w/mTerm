#ifndef SEARCH_H
#define SEARCH_H

typedef struct Search Search;
typedef struct Terminal Terminal;
typedef struct Scrollback Scrollback;

// Search creation
Search* search_create(Terminal* terminal, Scrollback* scrollback);
void search_destroy(Search* search);

// Search operations
int search_find(Search* search, const char* query);
int search_find_next(Search* search);
int search_find_prev(Search* search);
void search_clear(Search* search);

// Query management
void search_set_query(Search* search, const char* query);
const char* search_get_query(Search* search);

// Result navigation
int search_get_result_line(Search* search);
int search_get_result_column(Search* search);
int search_get_results_count(Search* search);

// Case sensitivity
void search_set_case_sensitive(Search* search, int case_sensitive);
int search_get_case_sensitive(Search* search);

// Regex support
int search_set_regex_pattern(Search* search, const char* regex_pattern);
const char* search_get_regex_pattern(Search* search);
int search_regex_find(Search* search, const char* pattern);
int search_regex_find_next(Search* search);
int search_regex_find_prev(Search* search);

// Find and replace
int search_find_and_replace(Search* search, const char* find_pattern, const char* replace_pattern);
int search_replace_next(Search* search, const char* replace_text);
int search_replace_all(Search* search, const char* find_pattern, const char* replace_pattern);
int search_get_replace_count(Search* search);

#endif // SEARCH_H

