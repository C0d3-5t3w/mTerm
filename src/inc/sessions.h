#ifndef SESSIONS_H
#define SESSIONS_H

typedef struct Session Session;
typedef struct SessionManager SessionManager;

// Session configuration
typedef struct {
    char shell_path[256];
    char working_dir[1024];
    char title[256];
    int width;
    int height;
    int tab_count;
    char theme_name[64];
} SessionConfig;

// Session creation and management
Session* session_create(const char* name);
void session_destroy(Session* session);

// Session properties
void session_set_name(Session* session, const char* name);
const char* session_get_name(Session* session);
void session_set_config(Session* session, SessionConfig* config);
SessionConfig* session_get_config(Session* session);

// Session persistence
int session_save_to_file(Session* session, const char* filepath);
Session* session_load_from_file(const char* filepath);

// Session manager
SessionManager* session_manager_create(const char* sessions_dir);
void session_manager_destroy(SessionManager* manager);

// Session management
int session_manager_save_current(SessionManager* manager, const char* session_name);
Session* session_manager_load_session(SessionManager* manager, const char* session_name);
int session_manager_delete_session(SessionManager* manager, const char* session_name);
int session_manager_list_sessions(SessionManager* manager, char** out_names, int max_sessions);

// Auto-save functionality
void session_manager_enable_autosave(SessionManager* manager, int enable);
int session_manager_get_autosave_enabled(SessionManager* manager);
void session_manager_set_autosave_interval(SessionManager* manager, int seconds);

#endif // SESSIONS_H
