#ifndef SHELL_INTEGRATION_H
#define SHELL_INTEGRATION_H

typedef struct ShellIntegration ShellIntegration;

typedef enum {
    SHELL_BASH,
    SHELL_ZSH,
    SHELL_FISH,
    SHELL_OTHER,
} ShellType;

// Shell integration creation
ShellIntegration* shell_integration_create(const char* shell_path);
void shell_integration_destroy(ShellIntegration* integration);

// Shell type detection
ShellType shell_integration_detect_shell(ShellIntegration* integration);

// Zsh-specific features
int shell_integration_setup_zsh_hooks(ShellIntegration* integration);
const char* shell_integration_get_zsh_init_code(ShellIntegration* integration);

// Fish-specific features
int shell_integration_setup_fish_hooks(ShellIntegration* integration);
const char* shell_integration_get_fish_init_code(ShellIntegration* integration);

// Bash-specific features
int shell_integration_setup_bash_hooks(ShellIntegration* integration);
const char* shell_integration_get_bash_init_code(ShellIntegration* integration);

// Command parsing and execution
const char* shell_integration_parse_command(ShellIntegration* integration, const char* input);
int shell_integration_execute_command(ShellIntegration* integration, const char* command);

// Prompt customization
void shell_integration_set_custom_prompt(ShellIntegration* integration, const char* prompt);
const char* shell_integration_get_custom_prompt(ShellIntegration* integration);

// Directory tracking
const char* shell_integration_get_current_directory(ShellIntegration* integration);
int shell_integration_set_current_directory(ShellIntegration* integration, const char* directory);

// Command history integration
int shell_integration_get_history(ShellIntegration* integration, char** out_commands, int max_commands);
int shell_integration_execute_from_history(ShellIntegration* integration, int history_index);

// Completion
char** shell_integration_get_completions(ShellIntegration* integration, const char* partial_command, int* out_count);

#endif // SHELL_INTEGRATION_H
