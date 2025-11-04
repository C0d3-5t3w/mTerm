#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <termios.h>
#include <signal.h>
#include <errno.h>

#import "shell.h"

#define BUFFER_SIZE 4096

typedef struct {
    int master_fd;
    int slave_fd;
    pid_t child_pid;
    int is_running;
    char output_buffer[BUFFER_SIZE];
    int buffer_pos;
} ShellData;

Shell* shell_create(void) {
    ShellData *shell = (ShellData *)malloc(sizeof(ShellData));
    if (!shell) return NULL;
    
    memset(shell, 0, sizeof(ShellData));
    shell->master_fd = -1;
    shell->slave_fd = -1;
    shell->child_pid = -1;
    shell->is_running = 0;
    
    return (Shell *)shell;
}

void shell_destroy(Shell* shell) {
    if (!shell) return;
    
    ShellData *shell_data = (ShellData *)shell;
    
    if (shell_data->is_running) {
        if (shell_data->child_pid > 0) {
            kill(shell_data->child_pid, SIGTERM);
            waitpid(shell_data->child_pid, NULL, 0);
        }
    }
    
    if (shell_data->master_fd >= 0) {
        close(shell_data->master_fd);
    }
    if (shell_data->slave_fd >= 0) {
        close(shell_data->slave_fd);
    }
    
    free(shell_data);
}

int shell_init_pty(Shell* shell) {
    if (!shell) return -1;
    
    ShellData *shell_data = (ShellData *)shell;
    
    // Open PTY master
    shell_data->master_fd = posix_openpt(O_RDWR);
    if (shell_data->master_fd < 0) {
        return -1;
    }
    
    // Grant access and unlock slave
    if (grantpt(shell_data->master_fd) < 0 || unlockpt(shell_data->master_fd) < 0) {
        close(shell_data->master_fd);
        shell_data->master_fd = -1;
        return -1;
    }
    
    // Get slave name and open it
    const char *slave_name = ptsname(shell_data->master_fd);
    if (!slave_name) {
        close(shell_data->master_fd);
        shell_data->master_fd = -1;
        return -1;
    }
    
    shell_data->slave_fd = open(slave_name, O_RDWR);
    if (shell_data->slave_fd < 0) {
        close(shell_data->master_fd);
        shell_data->master_fd = -1;
        return -1;
    }
    
    // Set non-blocking mode for master
    int flags = fcntl(shell_data->master_fd, F_GETFL);
    fcntl(shell_data->master_fd, F_SETFL, flags | O_NONBLOCK);
    
    // Fork and exec shell
    shell_data->child_pid = fork();
    if (shell_data->child_pid < 0) {
        close(shell_data->master_fd);
        close(shell_data->slave_fd);
        shell_data->master_fd = -1;
        shell_data->slave_fd = -1;
        return -1;
    }
    
    if (shell_data->child_pid == 0) {
        // Child process
        close(shell_data->master_fd);
        
        // Create new session
        setsid();
        
        // Open slave as stdin, stdout, stderr
        dup2(shell_data->slave_fd, 0);
        dup2(shell_data->slave_fd, 1);
        dup2(shell_data->slave_fd, 2);
        
        if (shell_data->slave_fd > 2) {
            close(shell_data->slave_fd);
        }
        
        // Execute shell
        const char *shell_path = "/bin/zsh";
        char *argv[] = { "zsh", NULL };
        execv(shell_path, argv);
        
        // If execv fails
        exit(1);
    } else {
        // Parent process
        close(shell_data->slave_fd);
        shell_data->slave_fd = -1;
        shell_data->is_running = 1;
    }
    
    return 0;
}

int shell_read_output(Shell* shell, char* buffer, int buffer_size) {
    if (!shell || !buffer || buffer_size <= 0) return -1;
    
    ShellData *shell_data = (ShellData *)shell;
    if (shell_data->master_fd < 0 || !shell_data->is_running) {
        return -1;
    }
    
    int n = read(shell_data->master_fd, buffer, buffer_size);
    
    if (n < 0) {
        if (errno == EAGAIN || errno == EWOULDBLOCK) {
            return 0;
        }
        return -1;
    }
    
    return n;
}

int shell_write_input(Shell* shell, const char* input, int length) {
    if (!shell || !input || length <= 0) return -1;
    
    ShellData *shell_data = (ShellData *)shell;
    if (shell_data->master_fd < 0 || !shell_data->is_running) {
        return -1;
    }
    
    int n = write(shell_data->master_fd, input, length);
    return n;
}

int shell_execute_command(Shell* shell, const char* command) {
    if (!shell || !command) return -1;
    
    ShellData *shell_data = (ShellData *)shell;
    if (shell_data->master_fd < 0) {
        return -1;
    }
    
    int len = strlen(command);
    return shell_write_input(shell, command, len);
}

const char* shell_get_output(Shell* shell) {
    if (!shell) return NULL;
    
    ShellData *shell_data = (ShellData *)shell;
    return shell_data->output_buffer;
}

int shell_is_running(Shell* shell) {
    if (!shell) return 0;
    
    ShellData *shell_data = (ShellData *)shell;
    
    if (!shell_data->is_running) {
        return 0;
    }
    
    // Check if child process is still alive
    if (shell_data->child_pid > 0) {
        int status;
        pid_t result = waitpid(shell_data->child_pid, &status, WNOHANG);
        if (result == shell_data->child_pid) {
            shell_data->is_running = 0;
            return 0;
        }
    }
    
    return 1;
}
