pub const Texture = struct {
	id: u32,

	pub fn initFromFile(path: []const u8) Texture {
		return .{
			.id = initTextureFromFileImpl(path.ptr, path.len),
		};
	}

	pub fn deinit(self: Texture) void {
		deinitTextureImpl(self.id);
	}
};

extern fn initTextureFromFileImpl(pathPtr: [*]const u8, pathLen: u32) u32;
extern fn deinitTextureImpl(id: u32) void;