#ifndef SHELL_H
#define SHELL_H

typedef struct Shell Shell;

// Shell creation and management
Shell* shell_create(void);
void shell_destroy(Shell* shell);

// Shell execution
int shell_execute_command(Shell* shell, const char* command);
const char* shell_get_output(Shell* shell);
int shell_is_running(Shell* shell);

// PTY management for interactive shell
int shell_init_pty(Shell* shell);
int shell_read_output(Shell* shell, char* buffer, int buffer_size);
int shell_write_input(Shell* shell, const char* input, int length);

// PTY resize
void shell_resize_pty(Shell* shell, int cols, int rows);

#endif // SHELL_H
