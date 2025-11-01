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

	const options = b.addOptions();
	options.addOption([]const []const u8, "assets", loadAssets(b));
	lib.root_module.addOptions("build_options", options);

    b.installArtifact(lib);
}

fn loadAssets(b: *std.Build) []const []const u8 {
	var list: std.ArrayList([]const u8) = .{};
	var folder = std.fs.cwd().openDir("src/assets", .{.iterate = true}) catch return &.{};
	defer folder.close();
	var walker = folder.walk(b.allocator) catch unreachable;
	while(walker.next() catch unreachable) |entry| {
		if(entry.kind != .file) continue;
		const path = b.allocator.dupe(u8, entry.path) catch unreachable;
		std.mem.replaceScalar(u8, path, '\\', '/');
		list.append(b.allocator, path) catch unreachable;
	}
	return list.toOwnedSlice(b.allocator) catch unreachable;
}