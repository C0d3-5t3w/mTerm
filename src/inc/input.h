#ifndef INPUT_H
#define INPUT_H

typedef struct InputHandler InputHandler;

// Input handler creation and management
InputHandler* input_create(void);
void input_destroy(InputHandler* input);

// Key code definitions
typedef enum {
    KEY_RETURN = 0x24,
    KEY_TAB = 0x30,
    KEY_SPACE = 0x31,
    KEY_BACKSPACE = 0x33,
    KEY_ESC = 0x35,
    KEY_DELETE = 0x75,
    KEY_UP = 0x7E,
    KEY_DOWN = 0x7D,
    KEY_LEFT = 0x7B,
    KEY_RIGHT = 0x7C,
} KeyCode;

typedef enum {
    ACTION_PRESSED = 0,
    ACTION_RELEASED = 1,
} KeyAction;

// Input handling
void input_handle_key(InputHandler* input, int key_code, int action);
int input_get_last_key(InputHandler* input);
const char* input_get_text_input(InputHandler* input);
void input_clear_buffer(InputHandler* input);

#endif // INPUT_H
