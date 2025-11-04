#import <Foundation/Foundation.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "shell_integration.h"

typedef struct {
    char shell_path[256];
    ShellType shell_type;
    char custom_prompt[512];
    char current_directory[1024];
    char *history[1000];
    int history_count;
} ShellIntegrationData;

ShellIntegration* shell_integration_create(const char* shell_path) {
    ShellIntegrationData *integration = (ShellIntegrationData *)malloc(sizeof(ShellIntegrationData));
    if (!integration) return NULL;
    
    memset(integration, 0, sizeof(ShellIntegrationData));
    
    if (shell_path) {
        strncpy(integration->shell_path, shell_path, sizeof(integration->shell_path) - 1);
    } else {
        const char *shell = getenv("SHELL");
        if (shell) {
            strncpy(integration->shell_path, shell, sizeof(integration->shell_path) - 1);
        }
    }
    
    // Detect shell type
    if (strstr(integration->shell_path, "zsh")) {
        integration->shell_type = SHELL_ZSH;
    } else if (strstr(integration->shell_path, "bash")) {
        integration->shell_type = SHELL_BASH;
    } else if (strstr(integration->shell_path, "fish")) {
        integration->shell_type = SHELL_FISH;
    } else {
        integration->shell_type = SHELL_OTHER;
    }
    
    // Get initial working directory
    if (getcwd(integration->current_directory, sizeof(integration->current_directory)) == NULL) {
        strcpy(integration->current_directory, getenv("HOME") ? getenv("HOME") : "/");
    }
    
    return (ShellIntegration *)integration;
}

void shell_integration_destroy(ShellIntegration* integration) {
    if (!integration) return;
    
    ShellIntegrationData *integration_data = (ShellIntegrationData *)integration;
    
    for (int i = 0; i < integration_data->history_count; i++) {
        if (integration_data->history[i]) {
            free(integration_data->history[i]);
        }
    }
    
    free(integration_data);
}

ShellType shell_integration_detect_shell(ShellIntegration* integration) {
    if (!integration) return SHELL_OTHER;
    return ((ShellIntegrationData *)integration)->shell_type;
}

int shell_integration_setup_zsh_hooks(ShellIntegration* integration) {
    if (!integration) return -1;
    if (shell_integration_detect_shell(integration) != SHELL_ZSH) return -1;
    
    // Zsh hook setup would go here
    return 0;
}

const char* shell_integration_get_zsh_init_code(ShellIntegration* integration) {
    static const char *zsh_init = 
        "# mTerm Zsh Integration\n"
        "export MTERM_INTEGRATED=1\n"
        "precmd() { pwd > /tmp/mterm_pwd; }\n"
        "preexec() { echo \"$1\" >> /tmp/mterm_history; }\n";
    
    return zsh_init;
}

int shell_integration_setup_fish_hooks(ShellIntegration* integration) {
    if (!integration) return -1;
    if (shell_integration_detect_shell(integration) != SHELL_FISH) return -1;
    
    // Fish hook setup would go here
    return 0;
}

const char* shell_integration_get_fish_init_code(ShellIntegration* integration) {
    static const char *fish_init = 
        "# mTerm Fish Integration\n"
        "set -x MTERM_INTEGRATED 1\n"
        "function __mterm_update_pwd --on-variable PWD\n"
        "    echo $PWD > /tmp/mterm_pwd\n"
        "end\n";
    
    return fish_init;
}

int shell_integration_setup_bash_hooks(ShellIntegration* integration) {
    if (!integration) return -1;
    if (shell_integration_detect_shell(integration) != SHELL_BASH) return -1;
    
    // Bash hook setup would go here
    return 0;
}

const char* shell_integration_get_bash_init_code(ShellIntegration* integration) {
    static const char *bash_init = 
        "# mTerm Bash Integration\n"
        "export MTERM_INTEGRATED=1\n"
        "PROMPT_COMMAND='pwd > /tmp/mterm_pwd'\n";
    
    return bash_init;
}

const char* shell_integration_parse_command(ShellIntegration* integration, const char* input) {
    if (!integration || !input) return NULL;
    
    // Parse command for execution
    return input;
}

int shell_integration_execute_command(ShellIntegration* integration, const char* command) {
    if (!integration || !command) return -1;
    
    // Command execution would go here
    return 0;
}

void shell_integration_set_custom_prompt(ShellIntegration* integration, const char* prompt) {
    if (!integration || !prompt) return;
    ShellIntegrationData *integration_data = (ShellIntegrationData *)integration;
    strncpy(integration_data->custom_prompt, prompt, sizeof(integration_data->custom_prompt) - 1);
}

const char* shell_integration_get_custom_prompt(ShellIntegration* integration) {
    if (!integration) return NULL;
    ShellIntegrationData *integration_data = (ShellIntegrationData *)integration;
    return integration_data->custom_prompt;
}

const char* shell_integration_get_current_directory(ShellIntegration* integration) {
    if (!integration) return NULL;
    return ((ShellIntegrationData *)integration)->current_directory;
}

int shell_integration_set_current_directory(ShellIntegration* integration, const char* directory) {
    if (!integration || !directory) return -1;
    
    ShellIntegrationData *integration_data = (ShellIntegrationData *)integration;
    
    if (chdir(directory) != 0) return -1;
    
    strncpy(integration_data->current_directory, directory, sizeof(integration_data->current_directory) - 1);
    return 0;
}

int shell_integration_get_history(ShellIntegration* integration, char** out_commands, int max_commands) {
    if (!integration || !out_commands || max_commands <= 0) return 0;
    
    ShellIntegrationData *integration_data = (ShellIntegrationData *)integration;
    
    int count = (integration_data->history_count < max_commands) ? integration_data->history_count : max_commands;
    
    for (int i = 0; i < count; i++) {
        out_commands[i] = integration_data->history[i];
    }
    
    return count;
}

int shell_integration_execute_from_history(ShellIntegration* integration, int history_index) {
    if (!integration || history_index < 0) return -1;
    
    ShellIntegrationData *integration_data = (ShellIntegrationData *)integration;
    
    if (history_index >= integration_data->history_count) return -1;
    
    return shell_integration_execute_command(integration, integration_data->history[history_index]);
}

char** shell_integration_get_completions(ShellIntegration* integration, const char* partial_command, int* out_count) {
    if (!integration || !partial_command || !out_count) return NULL;
    
    *out_count = 0;
    
    // Completion logic would go here
    char **completions = (char **)malloc(sizeof(char *) * 10);
    
    return completions;
}
