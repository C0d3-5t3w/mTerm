#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#import "input.h"

#define INPUT_BUFFER_SIZE 256

typedef struct {
    int last_key;
    int last_action;
    char text_buffer[INPUT_BUFFER_SIZE];
    int buffer_pos;
} InputHandlerData;

InputHandler* input_create(void) {
    InputHandlerData *input = (InputHandlerData *)malloc(sizeof(InputHandlerData));
    if (!input) return NULL;
    
    memset(input, 0, sizeof(InputHandlerData));
    input->last_key = -1;
    input->last_action = -1;
    
    return (InputHandler *)input;
}

void input_destroy(InputHandler* input) {
    if (!input) return;
    free(input);
}

void input_handle_key(InputHandler* input, int key_code, int action) {
    if (!input) return;
    
    InputHandlerData *input_data = (InputHandlerData *)input;
    input_data->last_key = key_code;
    input_data->last_action = action;
    
    // Only process key presses, not releases
    if (action != ACTION_PRESSED) {
        return;
    }
    
    // Handle special keys and printable characters
    switch (key_code) {
        case KEY_RETURN: {
            if (input_data->buffer_pos < INPUT_BUFFER_SIZE - 1) {
                input_data->text_buffer[input_data->buffer_pos++] = '\n';
                input_data->text_buffer[input_data->buffer_pos] = '\0';
            }
            break;
        }
        case KEY_BACKSPACE: {
            if (input_data->buffer_pos > 0) {
                input_data->buffer_pos--;
                input_data->text_buffer[input_data->buffer_pos] = '\0';
            }
            break;
        }
        case KEY_TAB: {
            if (input_data->buffer_pos < INPUT_BUFFER_SIZE - 1) {
                input_data->text_buffer[input_data->buffer_pos++] = '\t';
                input_data->text_buffer[input_data->buffer_pos] = '\0';
            }
            break;
        }
        case KEY_SPACE: {
            if (input_data->buffer_pos < INPUT_BUFFER_SIZE - 1) {
                input_data->text_buffer[input_data->buffer_pos++] = ' ';
                input_data->text_buffer[input_data->buffer_pos] = '\0';
            }
            break;
        }
        case KEY_ESC: {
            if (input_data->buffer_pos < INPUT_BUFFER_SIZE - 2) {
                input_data->text_buffer[input_data->buffer_pos++] = '\033';
                input_data->text_buffer[input_data->buffer_pos] = '\0';
            }
            break;
        }
        case KEY_DELETE: {
            if (input_data->buffer_pos > 0) {
                input_data->buffer_pos--;
                input_data->text_buffer[input_data->buffer_pos] = '\0';
            }
            break;
        }
        case KEY_UP: {
            if (input_data->buffer_pos < INPUT_BUFFER_SIZE - 3) {
                input_data->text_buffer[input_data->buffer_pos++] = '\033';
                input_data->text_buffer[input_data->buffer_pos++] = '[';
                input_data->text_buffer[input_data->buffer_pos++] = 'A';
                input_data->text_buffer[input_data->buffer_pos] = '\0';
            }
            break;
        }
        case KEY_DOWN: {
            if (input_data->buffer_pos < INPUT_BUFFER_SIZE - 3) {
                input_data->text_buffer[input_data->buffer_pos++] = '\033';
                input_data->text_buffer[input_data->buffer_pos++] = '[';
                input_data->text_buffer[input_data->buffer_pos++] = 'B';
                input_data->text_buffer[input_data->buffer_pos] = '\0';
            }
            break;
        }
        case KEY_LEFT: {
            if (input_data->buffer_pos < INPUT_BUFFER_SIZE - 3) {
                input_data->text_buffer[input_data->buffer_pos++] = '\033';
                input_data->text_buffer[input_data->buffer_pos++] = '[';
                input_data->text_buffer[input_data->buffer_pos++] = 'D';
                input_data->text_buffer[input_data->buffer_pos] = '\0';
            }
            break;
        }
        case KEY_RIGHT: {
            if (input_data->buffer_pos < INPUT_BUFFER_SIZE - 3) {
                input_data->text_buffer[input_data->buffer_pos++] = '\033';
                input_data->text_buffer[input_data->buffer_pos++] = '[';
                input_data->text_buffer[input_data->buffer_pos++] = 'C';
                input_data->text_buffer[input_data->buffer_pos] = '\0';
            }
            break;
        }
        default: {
            // Attempt to handle other printable characters
            // For simplicity, we'll skip unknown codes
            // A full implementation would map key codes to characters
            break;
        }
    }
}

int input_get_last_key(InputHandler* input) {
    if (!input) return -1;
    
    InputHandlerData *input_data = (InputHandlerData *)input;
    return input_data->last_key;
}

const char* input_get_text_input(InputHandler* input) {
    if (!input) return NULL;
    
    InputHandlerData *input_data = (InputHandlerData *)input;
    return input_data->text_buffer;
}

void input_clear_buffer(InputHandler* input) {
    if (!input) return;
    
    InputHandlerData *input_data = (InputHandlerData *)input;
    memset(input_data->text_buffer, 0, INPUT_BUFFER_SIZE);
    input_data->buffer_pos = 0;
}

void input_handle_character(InputHandler* input, const char *characters) {
    if (!input || !characters) return;
    
    InputHandlerData *input_data = (InputHandlerData *)input;
    
    // Add character to buffer (limited to printable ASCII)
    for (int i = 0; characters[i] && input_data->buffer_pos < INPUT_BUFFER_SIZE - 1; i++) {
        char c = characters[i];
        if (c >= 32 && c < 127) {  // Printable ASCII range
            input_data->text_buffer[input_data->buffer_pos++] = c;
            input_data->text_buffer[input_data->buffer_pos] = '\0';
        }
    }
}
