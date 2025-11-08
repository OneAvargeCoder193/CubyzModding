const cubyz = @import("cubyz");
const callback = cubyz.callback;
const Vec2f = cubyz.vec.Vec2f;
const Vec3f = cubyz.vec.Vec3f;
const Neighbor = cubyz.world.Neighbor;

pub const QuadInfo = enum(u16) {
	_,

	pub fn init(
		norm: Vec3f,
		corners: [4]Vec3f,
		cornerUv: [4]Vec2f,
		texSlot: u32,
		opaqueInLOD: u32,
	) void {
		return createQuadInfoImpl(
			norm[0], norm[1], norm[2],
			corners[0][0], corners[0][1], corners[0][2],
			corners[1][0], corners[1][1], corners[1][2],
			corners[2][0], corners[2][1], corners[2][2],
			corners[3][0], corners[3][1], corners[3][2],
			cornerUv[0][0], cornerUv[0][1],
			cornerUv[1][0], cornerUv[1][1],
			cornerUv[2][0], cornerUv[2][1],
			cornerUv[3][0], cornerUv[3][1],
			texSlot, opaqueInLOD
		);
	}

	pub fn normal(self: QuadInfo) Vec3f {
		var x: f32 = undefined;
		var y: f32 = undefined;
		var z: f32 = undefined;
		getQuadNormalImpl(self, &x, &y, &z);
		return .{x, y, z};
	}

	pub fn setNormal(self: QuadInfo, norm: Vec3f) void {
		setQuadNormalImpl(self, norm[0], norm[1], norm[2]);
	}

	pub fn corner(self: QuadInfo, i: u32) Vec3f {
		var x: f32 = undefined;
		var y: f32 = undefined;
		var z: f32 = undefined;
		getQuadCornerImpl(self, i, &x, &y, &z);
		return .{x, y, z};
	}

	pub fn setCorner(self: QuadInfo, i: u32, corn: Vec3f) void {
		setQuadCornerImpl(self, i, corn[0], corn[1], corn[2]);
	}

	pub fn cornerUV(self: QuadInfo, i: u32) Vec2f {
		var x: f32 = undefined;
		var y: f32 = undefined;
		getQuadCornerUVImpl(self, i, &x, &y);
		return .{x, y};
	}

	pub fn setCornerUV(self: QuadInfo, i: u32, uv: Vec2f) void {
		setQuadCornerUVImpl(self, i, uv[0], uv[1]);
	}

	pub fn textureSlot(self: QuadInfo) u32 {
		return getQuadTextureSlotImpl(self);
	}

	pub fn setTextureSlot(self: QuadInfo, texSlot: u32) void {
		setQuadTextureSlotImpl(self, texSlot);
	}

	pub fn opaqueInLod(self: QuadInfo) u32 {
		return getQuadOpaqueInLodImpl(self);
	}

	pub fn setOpaqueInLod(self: QuadInfo, opaqueInLOD: u32) void {
		setQuadOpaqueInLodImpl(self, opaqueInLOD);
	}
};

extern fn createQuadInfoImpl(
	normalX: f32, normalY: f32, normalZ: f32,
	corners1X: f32, corners1Y: f32, corners1Z: f32,
	corners2X: f32, corners2Y: f32, corners2Z: f32,
	corners3X: f32, corners3Y: f32, corners3Z: f32,
	corners4X: f32, corners4Y: f32, corners4Z: f32,
	cornerUv1X: f32, cornerUv1Y: f32,
	cornerUv2X: f32, cornerUv2Y: f32,
	cornerUv3X: f32, cornerUv3Y: f32,
	cornerUv4X: f32, cornerUv4Y: f32,
	textureSlot: u32,
	opaqueInLod: u32,
) QuadInfo;

extern fn getQuadNormalImpl(quad: QuadInfo, x: *f32, y: *f32, z: *f32) void;
extern fn setQuadNormalImpl(quad: QuadInfo, x: f32, y: f32, z: f32) void;
extern fn getQuadCornerImpl(quad: QuadInfo, i: u32, x: *f32, y: *f32, z: *f32) void;
extern fn setQuadCornerImpl(quad: QuadInfo, i: u32, x: f32, y: f32, z: f32) void;
extern fn getQuadCornerUVImpl(quad: QuadInfo, i: u32, x: *f32, y: *f32) void;
extern fn setQuadCornerUVImpl(quad: QuadInfo, i: u32, x: f32, y: f32) void;
extern fn getQuadTextureSlotImpl(quad: QuadInfo) u32;
extern fn setQuadTextureSlotImpl(quad: QuadInfo, texSlot: u32) void;
extern fn getQuadOpaqueInLodImpl(quad: QuadInfo) u32;
extern fn setQuadOpaqueInLodImpl(quad: QuadInfo, opaqueInLod: u32) void;

pub const Model = packed struct(u32){
	index: u32,

	pub fn getModelFromId(id: []const u8) Model {
		return getModelFromIdImpl(id.ptr, id.len);
	}

	pub fn offset(self: Model, off: u32) Model {
		return .{.index = self.index + off};
	}

	pub fn transformModel(self: Model, comptime func: anytype, comptime args: anytype) Model {
		const funcName = callback.registerCallback(struct{
			fn wrap(quad: QuadInfo) callconv(.{ .wasm_mvp = .{} }) void {
				@call(.auto, func, .{quad} ++ args);
			}
		}.wrap);
		return transformModelImpl(self, funcName.ptr, funcName.len);
	}
};

pub const RayIntersectionResult = struct {
	distance: f64,
	min: Vec3f,
	max: Vec3f,
	face: Neighbor,
};

extern fn getModelFromIdImpl(idPtr: [*]const u8, idLen: u32) Model;
extern fn transformModelImpl(index: Model, funcNamePtr: [*]const u8, funcNameLen: u32) Model;