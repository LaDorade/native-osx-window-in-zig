const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "osx-window-zig",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    b.installArtifact(exe);
    exe.root_module.addImport("objc", b.dependency("zig_objc", .{
        .target = target,
        .optimize = optimize,
    }).module("objc"));

    // // TODO: Remove when Zig supports compdb natively.
    // _ = b.run(&.{ "mkdir", "-p", ".cache/cdb" });

    exe.linkFramework("AppKit");
    // exe.linkFramework("CoreGraphics");
    // exe.linkFramework("Foundation");
    // exe.linkFramework("Metal");
    // exe.linkFramework("QuartzCore");
    exe.addIncludePath(b.path("include"));
    exe.addIncludePath(b.path("src"));
    exe.installHeadersDirectory(b.path("include"), "", .{});

    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
}
