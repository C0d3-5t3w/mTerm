const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const root_module = b.createModule(.{
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "mTerm",
        .root_module = root_module,
    });

    // Add all Objective-C source files
    const cflags = &[_][]const u8{};

    exe.addCSourceFile(.{
        .file = b.path("src/main.m"),
        .flags = cflags,
    });

    exe.addCSourceFile(.{
        .file = b.path("src/inc/window.m"),
        .flags = cflags,
    });

    exe.addCSourceFile(.{
        .file = b.path("src/inc/render.m"),
        .flags = cflags,
    });

    exe.addCSourceFile(.{
        .file = b.path("src/inc/shell.m"),
        .flags = cflags,
    });

    exe.addCSourceFile(.{
        .file = b.path("src/inc/input.m"),
        .flags = cflags,
    });

    exe.addCSourceFile(.{
        .file = b.path("src/inc/terminal.m"),
        .flags = cflags,
    });

    exe.addCSourceFile(.{
        .file = b.path("src/inc/clipboard.m"),
        .flags = cflags,
    });

    exe.addCSourceFile(.{
        .file = b.path("src/inc/scrollback.m"),
        .flags = cflags,
    });

    exe.addCSourceFile(.{
        .file = b.path("src/inc/themes.m"),
        .flags = cflags,
    });

    exe.addCSourceFile(.{
        .file = b.path("src/inc/tabs.m"),
        .flags = cflags,
    });

    exe.addCSourceFile(.{
        .file = b.path("src/inc/search.m"),
        .flags = cflags,
    });

    exe.addCSourceFile(.{
        .file = b.path("src/inc/sessions.m"),
        .flags = cflags,
    });

    exe.addCSourceFile(.{
        .file = b.path("src/inc/panes.m"),
        .flags = cflags,
    });

    exe.addCSourceFile(.{
        .file = b.path("src/inc/text_renderer.m"),
        .flags = cflags,
    });

    exe.addCSourceFile(.{
        .file = b.path("src/inc/url_detector.m"),
        .flags = cflags,
    });

    exe.addCSourceFile(.{
        .file = b.path("src/inc/image_renderer.m"),
        .flags = cflags,
    });

    exe.addCSourceFile(.{
        .file = b.path("src/inc/profiler.m"),
        .flags = cflags,
    });

    exe.addCSourceFile(.{
        .file = b.path("src/inc/shell_integration.m"),
        .flags = cflags,
    });

    exe.addCSourceFile(.{
        .file = b.path("src/inc/scripting.m"),
        .flags = cflags,
    });

    exe.linkLibC();

    exe.linkFramework("Cocoa");
    exe.linkFramework("Metal");
    exe.linkFramework("MetalKit");
    exe.linkFramework("QuartzCore");
    exe.linkFramework("CoreGraphics");
    exe.linkFramework("CoreText");
    exe.linkFramework("Foundation");
    exe.linkFramework("AppKit");

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
