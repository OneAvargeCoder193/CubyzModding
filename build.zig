const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.resolveTargetQuery(.{
		.cpu_arch = .wasm32,
		.os_tag = .freestanding,
		.cpu_model = .{.explicit = &std.Target.wasm.cpu.bleeding_edge},
		.cpu_features_add = std.Target.wasm.cpu.bleeding_edge.features,
	});
    const optimize = b.standardOptimizeOption(.{});

    const cubyz = b.addModule("cubyz", .{
		.root_source_file = b.path("cubyz/cubyz.zig"),
		.target = target,
		.optimize = optimize,
    });
	cubyz.addImport("cubyz", cubyz);

    const lib = b.addExecutable(.{
        .name = "Modding",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "cubyz", .module = cubyz },
            },
        }),
    });
	lib.rdynamic = true;
	lib.entry = .disabled;

    b.installArtifact(lib);
}