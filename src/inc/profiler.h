#ifndef PROFILER_H
#define PROFILER_H

typedef struct Profiler Profiler;
typedef struct ProfilerSample ProfilerSample;

typedef enum {
    METRIC_RENDERING_TIME,
    METRIC_SHELL_INPUT_TIME,
    METRIC_TERMINAL_UPDATE_TIME,
    METRIC_MEMORY_USAGE,
    METRIC_CPU_USAGE,
    METRIC_FPS,
} ProfilerMetric;

typedef struct {
    float min_value;
    float max_value;
    float avg_value;
    float current_value;
    int sample_count;
} ProfilerStats;

// Profiler creation
Profiler* profiler_create(void);
void profiler_destroy(Profiler* profiler);

// Profiling control
void profiler_start_measurement(Profiler* profiler, ProfilerMetric metric);
void profiler_end_measurement(Profiler* profiler, ProfilerMetric metric);
void profiler_record_sample(Profiler* profiler, ProfilerMetric metric, float value);

// Statistics
ProfilerStats profiler_get_stats(Profiler* profiler, ProfilerMetric metric);
float profiler_get_current_fps(Profiler* profiler);
float profiler_get_average_fps(Profiler* profiler);

// Reporting
void profiler_print_report(Profiler* profiler);
const char* profiler_get_report_string(Profiler* profiler);

// Configuration
void profiler_set_enabled(Profiler* profiler, int enabled);
int profiler_is_enabled(Profiler* profiler);
void profiler_set_sample_window(Profiler* profiler, int num_samples);
void profiler_reset_stats(Profiler* profiler);

#endif // PROFILER_H
