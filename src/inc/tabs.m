#include <stdlib.h>
#include <string.h>
#include "tabs.h"
#include "terminal.h"
#include "shell.h"

#define MAX_TAB_TITLE 128

typedef struct {
    char title[MAX_TAB_TITLE];
    Terminal *terminal;
    Shell *shell;
    int is_active;
} TabData;

typedef struct {
    TabData **tabs;
    int tab_count;
    int max_tabs;
    int active_tab_index;
} TabManagerData;

Tab* tab_create(const char* title) {
    TabData *tab = (TabData *)malloc(sizeof(TabData));
    if (!tab) return NULL;
    
    memset(tab, 0, sizeof(TabData));
    
    if (title) {
        strncpy(tab->title, title, MAX_TAB_TITLE - 1);
    } else {
        strcpy(tab->title, "Terminal");
    }
    
    tab->is_active = 0;
    tab->terminal = NULL;
    tab->shell = NULL;
    
    return (Tab *)tab;
}

void tab_destroy(Tab* tab) {
    if (!tab) return;
    
    TabData *tab_data = (TabData *)tab;
    
    // Note: We don't destroy terminal and shell here
    // as they may be managed elsewhere
    
    free(tab_data);
}

void tab_set_title(Tab* tab, const char* title) {
    if (!tab || !title) return;
    
    TabData *tab_data = (TabData *)tab;
    strncpy(tab_data->title, title, MAX_TAB_TITLE - 1);
}

const char* tab_get_title(Tab* tab) {
    if (!tab) return NULL;
    
    TabData *tab_data = (TabData *)tab;
    return tab_data->title;
}

void tab_set_terminal(Tab* tab, Terminal* terminal) {
    if (!tab) return;
    
    TabData *tab_data = (TabData *)tab;
    tab_data->terminal = terminal;
}

Terminal* tab_get_terminal(Tab* tab) {
    if (!tab) return NULL;
    
    TabData *tab_data = (TabData *)tab;
    return tab_data->terminal;
}

void tab_set_shell(Tab* tab, Shell* shell) {
    if (!tab) return;
    
    TabData *tab_data = (TabData *)tab;
    tab_data->shell = shell;
}

Shell* tab_get_shell(Tab* tab) {
    if (!tab) return NULL;
    
    TabData *tab_data = (TabData *)tab;
    return tab_data->shell;
}

TabManager* tab_manager_create(int max_tabs) {
    if (max_tabs <= 0) max_tabs = 10;  // Default to 10 tabs
    
    TabManagerData *manager = (TabManagerData *)malloc(sizeof(TabManagerData));
    if (!manager) return NULL;
    
    memset(manager, 0, sizeof(TabManagerData));
    
    manager->tabs = (TabData **)malloc(sizeof(TabData *) * max_tabs);
    if (!manager->tabs) {
        free(manager);
        return NULL;
    }
    
    memset(manager->tabs, 0, sizeof(TabData *) * max_tabs);
    
    manager->max_tabs = max_tabs;
    manager->tab_count = 0;
    manager->active_tab_index = -1;
    
    return (TabManager *)manager;
}

void tab_manager_destroy(TabManager* manager) {
    if (!manager) return;
    
    TabManagerData *manager_data = (TabManagerData *)manager;
    
    for (int i = 0; i < manager_data->tab_count; i++) {
        if (manager_data->tabs[i]) {
            tab_destroy((Tab *)manager_data->tabs[i]);
        }
    }
    
    free(manager_data->tabs);
    free(manager_data);
}

Tab* tab_manager_add_tab(TabManager* manager, const char* title) {
    if (!manager) return NULL;
    
    TabManagerData *manager_data = (TabManagerData *)manager;
    
    if (manager_data->tab_count >= manager_data->max_tabs) {
        return NULL;  // Tab limit reached
    }
    
    Tab *tab = tab_create(title);
    if (!tab) return NULL;
    
    manager_data->tabs[manager_data->tab_count] = (TabData *)tab;
    manager_data->tab_count++;
    
    // Auto-activate the first tab
    if (manager_data->active_tab_index < 0) {
        manager_data->active_tab_index = 0;
        ((TabData *)tab)->is_active = 1;
    }
    
    return tab;
}

int tab_manager_remove_tab(TabManager* manager, int tab_index) {
    if (!manager || tab_index < 0) return -1;
    
    TabManagerData *manager_data = (TabManagerData *)manager;
    
    if (tab_index >= manager_data->tab_count) {
        return -1;
    }
    
    // Destroy the tab
    if (manager_data->tabs[tab_index]) {
        tab_destroy((Tab *)manager_data->tabs[tab_index]);
    }
    
    // Shift remaining tabs
    for (int i = tab_index; i < manager_data->tab_count - 1; i++) {
        manager_data->tabs[i] = manager_data->tabs[i + 1];
    }
    
    manager_data->tab_count--;
    
    // Adjust active index if needed
    if (manager_data->active_tab_index >= manager_data->tab_count) {
        manager_data->active_tab_index = manager_data->tab_count - 1;
    }
    
    return 0;
}

Tab* tab_manager_get_tab(TabManager* manager, int tab_index) {
    if (!manager || tab_index < 0) return NULL;
    
    TabManagerData *manager_data = (TabManagerData *)manager;
    
    if (tab_index >= manager_data->tab_count) {
        return NULL;
    }
    
    return (Tab *)manager_data->tabs[tab_index];
}

Tab* tab_manager_get_active_tab(TabManager* manager) {
    if (!manager) return NULL;
    
    TabManagerData *manager_data = (TabManagerData *)manager;
    
    if (manager_data->active_tab_index < 0 || manager_data->active_tab_index >= manager_data->tab_count) {
        return NULL;
    }
    
    return (Tab *)manager_data->tabs[manager_data->active_tab_index];
}

int tab_manager_get_active_tab_index(TabManager* manager) {
    if (!manager) return -1;
    
    TabManagerData *manager_data = (TabManagerData *)manager;
    return manager_data->active_tab_index;
}

int tab_manager_set_active_tab(TabManager* manager, int tab_index) {
    if (!manager || tab_index < 0) return -1;
    
    TabManagerData *manager_data = (TabManagerData *)manager;
    
    if (tab_index >= manager_data->tab_count) {
        return -1;
    }
    
    // Deactivate old tab
    if (manager_data->active_tab_index >= 0 && manager_data->active_tab_index < manager_data->tab_count) {
        manager_data->tabs[manager_data->active_tab_index]->is_active = 0;
    }
    
    // Activate new tab
    manager_data->active_tab_index = tab_index;
    manager_data->tabs[tab_index]->is_active = 1;
    
    return 0;
}

int tab_manager_get_tab_count(TabManager* manager) {
    if (!manager) return 0;
    
    TabManagerData *manager_data = (TabManagerData *)manager;
    return manager_data->tab_count;
}

int tab_manager_next_tab(TabManager* manager) {
    if (!manager) return -1;
    
    TabManagerData *manager_data = (TabManagerData *)manager;
    
    if (manager_data->tab_count <= 1) {
        return manager_data->active_tab_index;
    }
    
    int next_index = (manager_data->active_tab_index + 1) % manager_data->tab_count;
    tab_manager_set_active_tab(manager, next_index);
    
    return next_index;
}

int tab_manager_prev_tab(TabManager* manager) {
    if (!manager) return -1;
    
    TabManagerData *manager_data = (TabManagerData *)manager;
    
    if (manager_data->tab_count <= 1) {
        return manager_data->active_tab_index;
    }
    
    int prev_index = (manager_data->active_tab_index - 1 + manager_data->tab_count) % manager_data->tab_count;
    tab_manager_set_active_tab(manager, prev_index);
    
    return prev_index;
}
