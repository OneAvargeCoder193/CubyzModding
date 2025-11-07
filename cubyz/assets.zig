pub fn registerAsset(name: []const u8, content: []const u8) void {
	registerAssetImpl(name.ptr, name.len, content.ptr, content.len);
}

extern fn registerAssetImpl(namePtr: [*]const u8, nameLen: u32, contentPtr: [*]const u8, contentLen: u32) void;