#import <Foundation/Foundation.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "panes.h"

typedef struct {
    int x;
    int y;
    int width;
    int height;
    int is_active;
    struct Pane *left_child;
    struct Pane *right_child;
    int is_split;
    SplitDirection split_direction;
} PaneData;

typedef struct {
    Pane **panes;
    int pane_count;
    int max_panes;
    Pane *active_pane;
    int window_width;
    int window_height;
} PaneManagerData;

Pane* pane_create(int x, int y, int width, int height) {
    PaneData *pane = (PaneData *)malloc(sizeof(PaneData));
    if (!pane) return NULL;
    
    memset(pane, 0, sizeof(PaneData));
    pane->x = x;
    pane->y = y;
    pane->width = width;
    pane->height = height;
    pane->is_active = 0;
    pane->left_child = NULL;
    pane->right_child = NULL;
    pane->is_split = 0;
    
    return (Pane *)pane;
}

void pane_destroy(Pane* pane) {
    if (!pane) return;
    
    PaneData *pane_data = (PaneData *)pane;
    
    if (pane_data->left_child) pane_destroy(pane_data->left_child);
    if (pane_data->right_child) pane_destroy(pane_data->right_child);
    
    free(pane_data);
}

int pane_get_x(Pane* pane) {
    if (!pane) return 0;
    return ((PaneData *)pane)->x;
}

int pane_get_y(Pane* pane) {
    if (!pane) return 0;
    return ((PaneData *)pane)->y;
}

int pane_get_width(Pane* pane) {
    if (!pane) return 0;
    return ((PaneData *)pane)->width;
}

int pane_get_height(Pane* pane) {
    if (!pane) return 0;
    return ((PaneData *)pane)->height;
}

void pane_set_active(Pane* pane, int active) {
    if (!pane) return;
    ((PaneData *)pane)->is_active = active;
}

int pane_is_active(Pane* pane) {
    if (!pane) return 0;
    return ((PaneData *)pane)->is_active;
}

PaneManager* pane_manager_create(int window_width, int window_height) {
    PaneManagerData *manager = (PaneManagerData *)malloc(sizeof(PaneManagerData));
    if (!manager) return NULL;
    
    memset(manager, 0, sizeof(PaneManagerData));
    
    manager->max_panes = 16;
    manager->panes = (Pane **)malloc(sizeof(Pane *) * manager->max_panes);
    if (!manager->panes) {
        free(manager);
        return NULL;
    }
    
    memset(manager->panes, 0, sizeof(Pane *) * manager->max_panes);
    manager->window_width = window_width;
    manager->window_height = window_height;
    
    // Create initial pane
    Pane *initial_pane = pane_create(0, 0, window_width, window_height);
    manager->panes[0] = initial_pane;
    manager->pane_count = 1;
    manager->active_pane = initial_pane;
    pane_set_active(initial_pane, 1);
    
    return (PaneManager *)manager;
}

void pane_manager_destroy(PaneManager* manager) {
    if (!manager) return;
    
    PaneManagerData *manager_data = (PaneManagerData *)manager;
    
    for (int i = 0; i < manager_data->pane_count; i++) {
        if (manager_data->panes[i]) {
            pane_destroy(manager_data->panes[i]);
        }
    }
    
    free(manager_data->panes);
    free(manager_data);
}

Pane* pane_manager_split_pane(PaneManager* manager, Pane* pane, SplitDirection direction) {
    if (!manager || !pane || manager == NULL) return NULL;
    
    PaneManagerData *manager_data = (PaneManagerData *)manager;
    PaneData *pane_data = (PaneData *)pane;
    
    if (manager_data->pane_count >= manager_data->max_panes) return NULL;
    
    pane_data->is_split = 1;
    pane_data->split_direction = direction;
    
    Pane *new_pane = NULL;
    
    if (direction == SPLIT_HORIZONTAL) {
        int new_height = pane_data->height / 2;
        pane_data->height = pane_data->height - new_height;
        
        new_pane = pane_create(pane_data->x, pane_data->y + pane_data->height, pane_data->width, new_height);
        pane_data->right_child = new_pane;
    } else {
        int new_width = pane_data->width / 2;
        pane_data->width = pane_data->width - new_width;
        
        new_pane = pane_create(pane_data->x + pane_data->width, pane_data->y, new_width, pane_data->height);
        pane_data->right_child = new_pane;
    }
    
    manager_data->panes[manager_data->pane_count] = new_pane;
    manager_data->pane_count++;
    
    return new_pane;
}

int pane_manager_close_pane(PaneManager* manager, Pane* pane) {
    if (!manager || !pane) return -1;
    
    PaneManagerData *manager_data = (PaneManagerData *)manager;
    
    // Don't close if it's the only pane
    if (manager_data->pane_count <= 1) return -1;
    
    for (int i = 0; i < manager_data->pane_count; i++) {
        if (manager_data->panes[i] == pane) {
            manager_data->panes[i] = manager_data->panes[manager_data->pane_count - 1];
            manager_data->pane_count--;
            
            pane_destroy(pane);
            
            if (manager_data->active_pane == pane && manager_data->pane_count > 0) {
                manager_data->active_pane = manager_data->panes[0];
                pane_set_active(manager_data->active_pane, 1);
            }
            
            return 0;
        }
    }
    
    return -1;
}

Pane* pane_manager_get_active_pane(PaneManager* manager) {
    if (!manager) return NULL;
    return ((PaneManagerData *)manager)->active_pane;
}

Pane* pane_manager_next_pane(PaneManager* manager) {
    if (!manager) return NULL;
    
    PaneManagerData *manager_data = (PaneManagerData *)manager;
    
    for (int i = 0; i < manager_data->pane_count; i++) {
        if (manager_data->panes[i] == manager_data->active_pane) {
            int next_index = (i + 1) % manager_data->pane_count;
            return manager_data->panes[next_index];
        }
    }
    
    return manager_data->panes[0];
}

Pane* pane_manager_prev_pane(PaneManager* manager) {
    if (!manager) return NULL;
    
    PaneManagerData *manager_data = (PaneManagerData *)manager;
    
    for (int i = 0; i < manager_data->pane_count; i++) {
        if (manager_data->panes[i] == manager_data->active_pane) {
            int prev_index = (i - 1 + manager_data->pane_count) % manager_data->pane_count;
            return manager_data->panes[prev_index];
        }
    }
    
    return manager_data->panes[manager_data->pane_count - 1];
}

int pane_manager_set_active_pane(PaneManager* manager, Pane* pane) {
    if (!manager || !pane) return -1;
    
    PaneManagerData *manager_data = (PaneManagerData *)manager;
    
    pane_set_active(manager_data->active_pane, 0);
    pane_set_active(pane, 1);
    manager_data->active_pane = pane;
    
    return 0;
}

Pane** pane_manager_get_all_panes(PaneManager* manager, int* out_count) {
    if (!manager || !out_count) return NULL;
    
    PaneManagerData *manager_data = (PaneManagerData *)manager;
    *out_count = manager_data->pane_count;
    
    return manager_data->panes;
}

int pane_manager_get_pane_count(PaneManager* manager) {
    if (!manager) return 0;
    return ((PaneManagerData *)manager)->pane_count;
}

void pane_manager_resize_all(PaneManager* manager, int window_width, int window_height) {
    if (!manager) return;
    
    PaneManagerData *manager_data = (PaneManagerData *)manager;
    manager_data->window_width = window_width;
    manager_data->window_height = window_height;
    
    if (manager_data->pane_count > 0) {
        PaneData *first_pane = (PaneData *)manager_data->panes[0];
        first_pane->width = window_width;
        first_pane->height = window_height;
    }
}

void pane_manager_resize_pane(PaneManager* manager, Pane* pane, int width, int height) {
    if (!manager || !pane) return;
    
    PaneData *pane_data = (PaneData *)pane;
    pane_data->width = width;
    pane_data->height = height;
}
