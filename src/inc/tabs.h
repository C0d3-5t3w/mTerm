#ifndef TABS_H
#define TABS_H

typedef struct Tab Tab;
typedef struct TabManager TabManager;

// Forward declarations
typedef struct Terminal Terminal;
typedef struct Shell Shell;

// Tab creation and management
Tab* tab_create(const char* title);
void tab_destroy(Tab* tab);

// Tab properties
void tab_set_title(Tab* tab, const char* title);
const char* tab_get_title(Tab* tab);
void tab_set_terminal(Tab* tab, Terminal* terminal);
Terminal* tab_get_terminal(Tab* tab);
void tab_set_shell(Tab* tab, Shell* shell);
Shell* tab_get_shell(Tab* tab);

// Tab manager
TabManager* tab_manager_create(int max_tabs);
void tab_manager_destroy(TabManager* manager);

// Tab management
Tab* tab_manager_add_tab(TabManager* manager, const char* title);
int tab_manager_remove_tab(TabManager* manager, int tab_index);
Tab* tab_manager_get_tab(TabManager* manager, int tab_index);
Tab* tab_manager_get_active_tab(TabManager* manager);

// Tab navigation
int tab_manager_get_active_tab_index(TabManager* manager);
int tab_manager_set_active_tab(TabManager* manager, int tab_index);
int tab_manager_get_tab_count(TabManager* manager);

// Tab switching
int tab_manager_next_tab(TabManager* manager);
int tab_manager_prev_tab(TabManager* manager);

#endif // TABS_H
