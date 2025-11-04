#ifndef URL_DETECTOR_H
#define URL_DETECTOR_H

typedef struct URLDetector URLDetector;

typedef enum {
    URL_HTTP,
    URL_HTTPS,
    URL_FTP,
    URL_MAILTO,
    URL_FILE,
} URLType;

typedef struct {
    URLType type;
    char url[2048];
    int start_column;
    int end_column;
    int line;
} URLMatch;

// URL detector creation
URLDetector* url_detector_create(void);
void url_detector_destroy(URLDetector* detector);

// Detection
URLMatch* url_detector_detect_urls(URLDetector* detector, const char* line, int* out_count);
int url_detector_has_url_at(URLDetector* detector, const char* line, int column);

// URL opening
int url_detector_open_url(URLDetector* detector, const char* url);
int url_detector_open_file(URLDetector* detector, const char* filepath);

// Configuration
void url_detector_set_browser(URLDetector* detector, const char* browser_path);
void url_detector_set_file_opener(URLDetector* detector, const char* opener_path);

#endif // URL_DETECTOR_H
