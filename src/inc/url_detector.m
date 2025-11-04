#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <regex.h>
#include "url_detector.h"

typedef struct {
    char browser_path[512];
    char file_opener_path[512];
} URLDetectorData;

URLDetector* url_detector_create(void) {
    URLDetectorData *detector = (URLDetectorData *)malloc(sizeof(URLDetectorData));
    if (!detector) return NULL;
    
    memset(detector, 0, sizeof(URLDetectorData));
    
    // Default values
    strcpy(detector->browser_path, "open");  // macOS 'open' command
    strcpy(detector->file_opener_path, "open");
    
    return (URLDetector *)detector;
}

void url_detector_destroy(URLDetector* detector) {
    if (!detector) return;
    free(detector);
}

URLMatch* url_detector_detect_urls(URLDetector* detector, const char* line, int* out_count) {
    if (!detector || !line || !out_count) return NULL;
    
    *out_count = 0;
    URLMatch *matches = (URLMatch *)malloc(sizeof(URLMatch) * 10);
    if (!matches) return NULL;
    
    int match_count = 0;
    const char *patterns[] = {
        "https?://[^\\s]+",
        "ftp://[^\\s]+",
        "mailto:[^\\s]+",
        "file://[^\\s]+",
    };
    
    URLType types[] = { URL_HTTP, URL_FTP, URL_MAILTO, URL_FILE };
    
    for (int p = 0; p < 4; p++) {
        regex_t regex;
        if (regcomp(&regex, patterns[p], REG_EXTENDED | REG_ICASE) == 0) {
            regmatch_t regmatch[1];
            const char *cursor = line;
            int offset = 0;
            
            while (regexec(&regex, cursor, 1, regmatch, 0) == 0 && match_count < 10) {
                int start = offset + regmatch[0].rm_so;
                int end = offset + regmatch[0].rm_eo;
                
                memset(&matches[match_count], 0, sizeof(URLMatch));
                matches[match_count].type = types[p];
                matches[match_count].start_column = start;
                matches[match_count].end_column = end;
                
                strncpy(matches[match_count].url, line + start, end - start);
                matches[match_count].url[end - start] = '\0';
                
                match_count++;
                
                offset += regmatch[0].rm_eo;
                cursor += regmatch[0].rm_eo;
            }
            
            regfree(&regex);
        }
    }
    
    *out_count = match_count;
    return matches;
}

int url_detector_has_url_at(URLDetector* detector, const char* line, int column) {
    if (!detector || !line || column < 0) return 0;
    
    int count = 0;
    URLMatch *matches = url_detector_detect_urls(detector, line, &count);
    
    for (int i = 0; i < count; i++) {
        if (column >= matches[i].start_column && column <= matches[i].end_column) {
            free(matches);
            return 1;
        }
    }
    
    if (matches) free(matches);
    return 0;
}

int url_detector_open_url(URLDetector* detector, const char* url) {
    if (!detector || !url) return -1;
    
    @autoreleasepool {
        URLDetectorData *detector_data = (URLDetectorData *)detector;
        
        NSString *url_string = [NSString stringWithUTF8String:url];
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url_string]];
        
        return 0;
    }
}

int url_detector_open_file(URLDetector* detector, const char* filepath) {
    if (!detector || !filepath) return -1;
    
    @autoreleasepool {
        NSString *path = [NSString stringWithUTF8String:filepath];
        [[NSWorkspace sharedWorkspace] openFile:path];
        
        return 0;
    }
}

void url_detector_set_browser(URLDetector* detector, const char* browser_path) {
    if (!detector || !browser_path) return;
    URLDetectorData *detector_data = (URLDetectorData *)detector;
    strncpy(detector_data->browser_path, browser_path, sizeof(detector_data->browser_path) - 1);
}

void url_detector_set_file_opener(URLDetector* detector, const char* opener_path) {
    if (!detector || !opener_path) return;
    URLDetectorData *detector_data = (URLDetectorData *)detector;
    strncpy(detector_data->file_opener_path, opener_path, sizeof(detector_data->file_opener_path) - 1);
}
