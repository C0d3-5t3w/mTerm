#import <Foundation/Foundation.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "sessions.h"

typedef struct {
    char name[256];
    char shell_path[256];
    char working_dir[1024];
    char title[256];
    int width;
    int height;
    int tab_count;
    char theme_name[64];
    time_t created_time;
    time_t last_modified;
} SessionData;

typedef struct {
    char sessions_dir[1024];
    int autosave_enabled;
    int autosave_interval;
    time_t last_autosave;
} SessionManagerData;

Session* session_create(const char* name) {
    SessionData *session = (SessionData *)malloc(sizeof(SessionData));
    if (!session) return NULL;
    
    memset(session, 0, sizeof(SessionData));
    
    if (name) {
        strncpy(session->name, name, sizeof(session->name) - 1);
    }
    
    session->created_time = time(NULL);
    session->last_modified = time(NULL);
    
    // Default values
    session->width = 120;
    session->height = 50;
    session->tab_count = 1;
    strcpy(session->theme_name, "Dark");
    strcpy(session->shell_path, "/bin/zsh");
    strcpy(session->working_dir, getenv("HOME") ? getenv("HOME") : "/");
    
    return (Session *)session;
}

void session_destroy(Session* session) {
    if (!session) return;
    free(session);
}

void session_set_name(Session* session, const char* name) {
    if (!session || !name) return;
    SessionData *session_data = (SessionData *)session;
    strncpy(session_data->name, name, sizeof(session_data->name) - 1);
    session_data->last_modified = time(NULL);
}

const char* session_get_name(Session* session) {
    if (!session) return NULL;
    SessionData *session_data = (SessionData *)session;
    return session_data->name;
}

void session_set_config(Session* session, SessionConfig* config) {
    if (!session || !config) return;
    SessionData *session_data = (SessionData *)session;
    
    strncpy(session_data->shell_path, config->shell_path, sizeof(session_data->shell_path) - 1);
    strncpy(session_data->working_dir, config->working_dir, sizeof(session_data->working_dir) - 1);
    strncpy(session_data->title, config->title, sizeof(session_data->title) - 1);
    strncpy(session_data->theme_name, config->theme_name, sizeof(session_data->theme_name) - 1);
    
    session_data->width = config->width;
    session_data->height = config->height;
    session_data->tab_count = config->tab_count;
    session_data->last_modified = time(NULL);
}

SessionConfig* session_get_config(Session* session) {
    if (!session) return NULL;
    
    SessionData *session_data = (SessionData *)session;
    SessionConfig *config = (SessionConfig *)malloc(sizeof(SessionConfig));
    if (!config) return NULL;
    
    memset(config, 0, sizeof(SessionConfig));
    
    strncpy(config->shell_path, session_data->shell_path, sizeof(config->shell_path) - 1);
    strncpy(config->working_dir, session_data->working_dir, sizeof(config->working_dir) - 1);
    strncpy(config->title, session_data->title, sizeof(config->title) - 1);
    strncpy(config->theme_name, session_data->theme_name, sizeof(config->theme_name) - 1);
    
    config->width = session_data->width;
    config->height = session_data->height;
    config->tab_count = session_data->tab_count;
    
    return config;
}

int session_save_to_file(Session* session, const char* filepath) {
    if (!session || !filepath) return -1;
    
    @autoreleasepool {
        SessionData *session_data = (SessionData *)session;
        
        // Create JSON dictionary
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        
        [dict setObject:[NSString stringWithUTF8String:session_data->name] forKey:@"name"];
        [dict setObject:[NSString stringWithUTF8String:session_data->shell_path] forKey:@"shell_path"];
        [dict setObject:[NSString stringWithUTF8String:session_data->working_dir] forKey:@"working_dir"];
        [dict setObject:[NSString stringWithUTF8String:session_data->title] forKey:@"title"];
        [dict setObject:[NSString stringWithUTF8String:session_data->theme_name] forKey:@"theme"];
        
        [dict setObject:@(session_data->width) forKey:@"width"];
        [dict setObject:@(session_data->height) forKey:@"height"];
        [dict setObject:@(session_data->tab_count) forKey:@"tab_count"];
        [dict setObject:@(session_data->created_time) forKey:@"created_time"];
        [dict setObject:@(session_data->last_modified) forKey:@"last_modified"];
        
        // Write to file
        NSString *json_path = [NSString stringWithUTF8String:filepath];
        NSError *error = nil;
        
        NSData *json_data = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
        if (!json_data || ![json_data writeToFile:json_path atomically:YES]) {
            return -1;
        }
        
        return 0;
    }
}

Session* session_load_from_file(const char* filepath) {
    if (!filepath) return NULL;
    
    @autoreleasepool {
        NSString *json_path = [NSString stringWithUTF8String:filepath];
        NSData *json_data = [NSData dataWithContentsOfFile:json_path];
        
        if (!json_data) return NULL;
        
        NSError *error = nil;
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:json_data options:0 error:&error];
        
        if (!dict) return NULL;
        
        Session *session = session_create([[dict objectForKey:@"name"] UTF8String]);
        if (!session) return NULL;
        
        SessionData *session_data = (SessionData *)session;
        
        if ([dict objectForKey:@"shell_path"]) {
            strncpy(session_data->shell_path, [[dict objectForKey:@"shell_path"] UTF8String], sizeof(session_data->shell_path) - 1);
        }
        if ([dict objectForKey:@"working_dir"]) {
            strncpy(session_data->working_dir, [[dict objectForKey:@"working_dir"] UTF8String], sizeof(session_data->working_dir) - 1);
        }
        if ([dict objectForKey:@"title"]) {
            strncpy(session_data->title, [[dict objectForKey:@"title"] UTF8String], sizeof(session_data->title) - 1);
        }
        if ([dict objectForKey:@"theme"]) {
            strncpy(session_data->theme_name, [[dict objectForKey:@"theme"] UTF8String], sizeof(session_data->theme_name) - 1);
        }
        
        if ([dict objectForKey:@"width"]) {
            session_data->width = [[dict objectForKey:@"width"] intValue];
        }
        if ([dict objectForKey:@"height"]) {
            session_data->height = [[dict objectForKey:@"height"] intValue];
        }
        if ([dict objectForKey:@"tab_count"]) {
            session_data->tab_count = [[dict objectForKey:@"tab_count"] intValue];
        }
        if ([dict objectForKey:@"created_time"]) {
            session_data->created_time = [[dict objectForKey:@"created_time"] longValue];
        }
        if ([dict objectForKey:@"last_modified"]) {
            session_data->last_modified = [[dict objectForKey:@"last_modified"] longValue];
        }
        
        return session;
    }
}

SessionManager* session_manager_create(const char* sessions_dir) {
    SessionManagerData *manager = (SessionManagerData *)malloc(sizeof(SessionManagerData));
    if (!manager) return NULL;
    
    memset(manager, 0, sizeof(SessionManagerData));
    
    if (sessions_dir) {
        strncpy(manager->sessions_dir, sessions_dir, sizeof(manager->sessions_dir) - 1);
    } else {
        // Default to ~/.mterm/sessions
        const char *home = getenv("HOME");
        if (home) {
            snprintf(manager->sessions_dir, sizeof(manager->sessions_dir), "%s/.mterm/sessions", home);
        }
    }
    
    manager->autosave_enabled = 0;
    manager->autosave_interval = 300; // 5 minutes default
    manager->last_autosave = time(NULL);
    
    // Create sessions directory if it doesn't exist
    @autoreleasepool {
        NSString *dir_path = [NSString stringWithUTF8String:manager->sessions_dir];
        NSFileManager *fm = [NSFileManager defaultManager];
        [fm createDirectoryAtPath:dir_path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return (SessionManager *)manager;
}

void session_manager_destroy(SessionManager* manager) {
    if (!manager) return;
    free(manager);
}

int session_manager_save_current(SessionManager* manager, const char* session_name) {
    if (!manager || !session_name) return -1;
    
    SessionManagerData *manager_data = (SessionManagerData *)manager;
    
    Session *session = session_create(session_name);
    if (!session) return -1;
    
    @autoreleasepool {
        NSString *dir_path = [NSString stringWithUTF8String:manager_data->sessions_dir];
        NSString *session_filename = [[NSString stringWithUTF8String:session_name] stringByAppendingPathExtension:@"json"];
        NSString *filepath = [dir_path stringByAppendingPathComponent:session_filename];
        
        int result = session_save_to_file(session, [filepath UTF8String]);
        
        session_destroy(session);
        return result;
    }
}

Session* session_manager_load_session(SessionManager* manager, const char* session_name) {
    if (!manager || !session_name) return NULL;
    
    SessionManagerData *manager_data = (SessionManagerData *)manager;
    
    @autoreleasepool {
        NSString *dir_path = [NSString stringWithUTF8String:manager_data->sessions_dir];
        NSString *session_filename = [[NSString stringWithUTF8String:session_name] stringByAppendingPathExtension:@"json"];
        NSString *filepath = [dir_path stringByAppendingPathComponent:session_filename];
        
        return session_load_from_file([filepath UTF8String]);
    }
}

int session_manager_delete_session(SessionManager* manager, const char* session_name) {
    if (!manager || !session_name) return -1;
    
    SessionManagerData *manager_data = (SessionManagerData *)manager;
    
    @autoreleasepool {
        NSString *dir_path = [NSString stringWithUTF8String:manager_data->sessions_dir];
        NSString *session_filename = [[NSString stringWithUTF8String:session_name] stringByAppendingPathExtension:@"json"];
        NSString *filepath = [dir_path stringByAppendingPathComponent:session_filename];
        
        NSFileManager *fm = [NSFileManager defaultManager];
        NSError *error = nil;
        
        if ([fm removeItemAtPath:filepath error:&error]) {
            return 0;
        }
        
        return -1;
    }
}

int session_manager_list_sessions(SessionManager* manager, char** out_names, int max_sessions) {
    if (!manager || !out_names || max_sessions <= 0) return -1;
    
    SessionManagerData *manager_data = (SessionManagerData *)manager;
    
    @autoreleasepool {
        NSString *dir_path = [NSString stringWithUTF8String:manager_data->sessions_dir];
        NSFileManager *fm = [NSFileManager defaultManager];
        NSArray *files = [fm contentsOfDirectoryAtPath:dir_path error:nil];
        
        int count = 0;
        for (NSString *file in files) {
            if ([file hasSuffix:@".json"] && count < max_sessions) {
                NSString *name = [file stringByDeletingPathExtension];
                out_names[count] = strdup([name UTF8String]);
                count++;
            }
        }
        
        return count;
    }
}

void session_manager_enable_autosave(SessionManager* manager, int enable) {
    if (!manager) return;
    SessionManagerData *manager_data = (SessionManagerData *)manager;
    manager_data->autosave_enabled = enable;
}

int session_manager_get_autosave_enabled(SessionManager* manager) {
    if (!manager) return 0;
    SessionManagerData *manager_data = (SessionManagerData *)manager;
    return manager_data->autosave_enabled;
}

void session_manager_set_autosave_interval(SessionManager* manager, int seconds) {
    if (!manager || seconds <= 0) return;
    SessionManagerData *manager_data = (SessionManagerData *)manager;
    manager_data->autosave_interval = seconds;
}
