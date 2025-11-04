#ifndef SCRIPTING_H
#define SCRIPTING_H

typedef struct ScriptingEngine ScriptingEngine;
typedef struct ScriptContext ScriptContext;

typedef enum {
    SCRIPT_LUA,
    SCRIPT_JAVASCRIPT,
} ScriptingLanguage;

typedef int (*ScriptFunction)(ScriptContext* ctx, void* user_data);

// Scripting engine creation
ScriptingEngine* scripting_engine_create(ScriptingLanguage language);
void scripting_engine_destroy(ScriptingEngine* engine);

// Script execution
int scripting_engine_execute_script(ScriptingEngine* engine, const char* script);
int scripting_engine_execute_file(ScriptingEngine* engine, const char* filepath);

// Script context
ScriptContext* scripting_engine_create_context(ScriptingEngine* engine);
void scripting_engine_destroy_context(ScriptContext* ctx);

// API registration
int scripting_engine_register_function(ScriptingEngine* engine, const char* name, ScriptFunction func, void* user_data);
int scripting_engine_register_object(ScriptingEngine* engine, const char* name, void* object_ptr);

// Built-in APIs
int scripting_engine_register_builtin_terminal_api(ScriptingEngine* engine);
int scripting_engine_register_builtin_shell_api(ScriptingEngine* engine);
int scripting_engine_register_builtin_window_api(ScriptingEngine* engine);
int scripting_engine_register_builtin_clipboard_api(ScriptingEngine* engine);

// Error handling
const char* scripting_engine_get_last_error(ScriptingEngine* engine);
void scripting_engine_clear_error(ScriptingEngine* engine);

// Event handling
typedef int (*ScriptEventHandler)(ScriptContext* ctx, const char* event_name, void* user_data);
int scripting_engine_register_event_handler(ScriptingEngine* engine, const char* event_name, ScriptEventHandler handler, void* user_data);
int scripting_engine_trigger_event(ScriptingEngine* engine, const char* event_name, const char* data);

// Configuration
void scripting_engine_set_timeout(ScriptingEngine* engine, int milliseconds);
void scripting_engine_enable_sandbox(ScriptingEngine* engine, int enable);

#endif // SCRIPTING_H
