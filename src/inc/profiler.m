#import <Foundation/Foundation.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <sys/time.h>
#include "profiler.h"

#define MAX_METRICS 6
#define MAX_SAMPLES 1000

typedef struct {
    ProfilerMetric metric;
    float samples[MAX_SAMPLES];
    int sample_index;
    int sample_count;
    struct timeval start_time;
} MetricData;

typedef struct {
    MetricData metrics[MAX_METRICS];
    int enabled;
    int sample_window;
} ProfilerData;

Profiler* profiler_create(void) {
    ProfilerData *profiler = (ProfilerData *)malloc(sizeof(ProfilerData));
    if (!profiler) return NULL;
    
    memset(profiler, 0, sizeof(ProfilerData));
    
    profiler->enabled = 0;
    profiler->sample_window = 100;
    
    // Initialize metrics
    profiler->metrics[0].metric = METRIC_RENDERING_TIME;
    profiler->metrics[1].metric = METRIC_SHELL_INPUT_TIME;
    profiler->metrics[2].metric = METRIC_TERMINAL_UPDATE_TIME;
    profiler->metrics[3].metric = METRIC_MEMORY_USAGE;
    profiler->metrics[4].metric = METRIC_CPU_USAGE;
    profiler->metrics[5].metric = METRIC_FPS;
    
    for (int i = 0; i < MAX_METRICS; i++) {
        profiler->metrics[i].sample_index = 0;
        profiler->metrics[i].sample_count = 0;
    }
    
    return (Profiler *)profiler;
}

void profiler_destroy(Profiler* profiler) {
    if (!profiler) return;
    free(profiler);
}

void profiler_start_measurement(Profiler* profiler, ProfilerMetric metric) {
    if (!profiler || !((ProfilerData *)profiler)->enabled) return;
    
    ProfilerData *profiler_data = (ProfilerData *)profiler;
    
    for (int i = 0; i < MAX_METRICS; i++) {
        if (profiler_data->metrics[i].metric == metric) {
            gettimeofday(&profiler_data->metrics[i].start_time, NULL);
            break;
        }
    }
}

void profiler_end_measurement(Profiler* profiler, ProfilerMetric metric) {
    if (!profiler || !((ProfilerData *)profiler)->enabled) return;
    
    ProfilerData *profiler_data = (ProfilerData *)profiler;
    struct timeval end_time;
    gettimeofday(&end_time, NULL);
    
    for (int i = 0; i < MAX_METRICS; i++) {
        if (profiler_data->metrics[i].metric == metric) {
            struct timeval *start = &profiler_data->metrics[i].start_time;
            
            float elapsed_ms = (end_time.tv_sec - start->tv_sec) * 1000.0f +
                               (end_time.tv_usec - start->tv_usec) / 1000.0f;
            
            profiler_record_sample(profiler, metric, elapsed_ms);
            break;
        }
    }
}

void profiler_record_sample(Profiler* profiler, ProfilerMetric metric, float value) {
    if (!profiler) return;
    
    ProfilerData *profiler_data = (ProfilerData *)profiler;
    
    for (int i = 0; i < MAX_METRICS; i++) {
        if (profiler_data->metrics[i].metric == metric) {
            MetricData *metric_data = &profiler_data->metrics[i];
            
            metric_data->samples[metric_data->sample_index] = value;
            metric_data->sample_index = (metric_data->sample_index + 1) % MAX_SAMPLES;
            
            if (metric_data->sample_count < MAX_SAMPLES) {
                metric_data->sample_count++;
            }
            
            break;
        }
    }
}

ProfilerStats profiler_get_stats(Profiler* profiler, ProfilerMetric metric) {
    ProfilerStats stats = {0};
    
    if (!profiler) return stats;
    
    ProfilerData *profiler_data = (ProfilerData *)profiler;
    
    for (int i = 0; i < MAX_METRICS; i++) {
        if (profiler_data->metrics[i].metric == metric) {
            MetricData *metric_data = &profiler_data->metrics[i];
            
            if (metric_data->sample_count == 0) return stats;
            
            stats.min_value = 999999.0f;
            stats.max_value = 0.0f;
            stats.avg_value = 0.0f;
            stats.sample_count = metric_data->sample_count;
            
            for (int j = 0; j < metric_data->sample_count; j++) {
                float val = metric_data->samples[j];
                if (val < stats.min_value) stats.min_value = val;
                if (val > stats.max_value) stats.max_value = val;
                stats.avg_value += val;
            }
            
            stats.avg_value /= metric_data->sample_count;
            stats.current_value = metric_data->samples[(metric_data->sample_index - 1 + MAX_SAMPLES) % MAX_SAMPLES];
            
            break;
        }
    }
    
    return stats;
}

float profiler_get_current_fps(Profiler* profiler) {
    if (!profiler) return 0.0f;
    
    ProfilerStats stats = profiler_get_stats(profiler, METRIC_FPS);
    return stats.current_value;
}

float profiler_get_average_fps(Profiler* profiler) {
    if (!profiler) return 0.0f;
    
    ProfilerStats stats = profiler_get_stats(profiler, METRIC_FPS);
    return stats.avg_value;
}

void profiler_print_report(Profiler* profiler) {
    if (!profiler) return;
    
    printf("\n=== Performance Report ===\n");
    
    const char *metric_names[] = {
        "Rendering Time",
        "Shell Input Time",
        "Terminal Update Time",
        "Memory Usage",
        "CPU Usage",
        "FPS"
    };
    
    ProfilerData *profiler_data = (ProfilerData *)profiler;
    
    for (int i = 0; i < MAX_METRICS; i++) {
        ProfilerStats stats = profiler_get_stats(profiler, profiler_data->metrics[i].metric);
        
        if (stats.sample_count > 0) {
            printf("%s: min=%.2f, max=%.2f, avg=%.2f, current=%.2f\n",
                   metric_names[i], stats.min_value, stats.max_value, stats.avg_value, stats.current_value);
        }
    }
}

const char* profiler_get_report_string(Profiler* profiler) {
    // Implementation would return a formatted string
    // This is simplified for the placeholder
    static char buffer[1024];
    memset(buffer, 0, sizeof(buffer));
    
    if (!profiler) return buffer;
    
    snprintf(buffer, sizeof(buffer), "Performance Report: FPS=%.1f\n",
             profiler_get_average_fps(profiler));
    
    return buffer;
}

void profiler_set_enabled(Profiler* profiler, int enabled) {
    if (!profiler) return;
    ((ProfilerData *)profiler)->enabled = enabled;
}

int profiler_is_enabled(Profiler* profiler) {
    if (!profiler) return 0;
    return ((ProfilerData *)profiler)->enabled;
}

void profiler_set_sample_window(Profiler* profiler, int num_samples) {
    if (!profiler || num_samples <= 0) return;
    ((ProfilerData *)profiler)->sample_window = num_samples;
}

void profiler_reset_stats(Profiler* profiler) {
    if (!profiler) return;
    
    ProfilerData *profiler_data = (ProfilerData *)profiler;
    
    for (int i = 0; i < MAX_METRICS; i++) {
        profiler_data->metrics[i].sample_index = 0;
        profiler_data->metrics[i].sample_count = 0;
        memset(profiler_data->metrics[i].samples, 0, sizeof(profiler_data->metrics[i].samples));
    }
}
