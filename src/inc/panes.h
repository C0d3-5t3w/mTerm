#ifndef PANES_H
#define PANES_H

typedef struct Pane Pane;
typedef struct PaneManager PaneManager;

typedef enum {
    SPLIT_HORIZONTAL,
    SPLIT_VERTICAL,
} SplitDirection;

// Pane creation and management
Pane* pane_create(int x, int y, int width, int height);
void pane_destroy(Pane* pane);

// Pane properties
int pane_get_x(Pane* pane);
int pane_get_y(Pane* pane);
int pane_get_width(Pane* pane);
int pane_get_height(Pane* pane);
void pane_set_active(Pane* pane, int active);
int pane_is_active(Pane* pane);

// Pane manager (manages multiple panes in a window)
PaneManager* pane_manager_create(int window_width, int window_height);
void pane_manager_destroy(PaneManager* manager);

// Pane splitting
Pane* pane_manager_split_pane(PaneManager* manager, Pane* pane, SplitDirection direction);
int pane_manager_close_pane(PaneManager* manager, Pane* pane);

// Pane navigation
Pane* pane_manager_get_active_pane(PaneManager* manager);
Pane* pane_manager_next_pane(PaneManager* manager);
Pane* pane_manager_prev_pane(PaneManager* manager);
int pane_manager_set_active_pane(PaneManager* manager, Pane* pane);

// Pane queries
Pane** pane_manager_get_all_panes(PaneManager* manager, int* out_count);
int pane_manager_get_pane_count(PaneManager* manager);

// Pane resizing
void pane_manager_resize_all(PaneManager* manager, int window_width, int window_height);
void pane_manager_resize_pane(PaneManager* manager, Pane* pane, int width, int height);

#endif // PANES_H
