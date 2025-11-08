const std = @import("std");

const cubyz = @import("cubyz");
const callback = cubyz.callback;
const Vec2f = cubyz.vec.Vec2f;
const Vec3f = cubyz.vec.Vec3f;
const Neighbor = cubyz.world.Neighbor;

pub const QuadInfo = extern struct {
	normal: [3]f32 align(16),
	corners: [4][3]f32,
	cornerUV: [4][2]f32 align(8),
	textureSlot: u32,
	opaqueInLod: u32 = 0,
};

pub const Model = packed struct(u32){
	index: u32,

	pub fn init(quads: []QuadInfo) Model {
		const data: []u8 = @ptrCast(quads);
		return modelInitImpl(data.ptr, data.len);
	}

	pub fn getModelFromId(id: []const u8) Model {
		return getModelFromIdImpl(id.ptr, id.len);
	}

	pub fn getRawFaces(self: Model) []QuadInfo {
		var len: u32 = undefined;
		const ptr = getRawFacesImpl(self, &len);
		return ptr[0..len];
	}

	pub fn offset(self: Model, off: u32) Model {
		return .{.index = self.index + off};
	}

	pub fn transformModel(self: Model, transformFunction: anytype, transformFunctionParameters: anytype) Model {
		const quadList = self.getRawFaces();
		defer cubyz.allocator.free(quadList);
		for(quadList) |*quad| {
			@call(.auto, transformFunction, .{quad} ++ transformFunctionParameters);
		}
		return Model.init(quadList);
	}
};

pub const RayIntersectionResult = struct {
	distance: f64,
	min: Vec3f,
	max: Vec3f,
	face: Neighbor,
};

extern fn modelInitImpl(dataPtr: [*]u8, dataLen: u32) Model;
extern fn getModelFromIdImpl(idPtr: [*]const u8, idLen: u32) Model;
extern fn getRawFacesImpl(index: Model, len: *u32) [*]QuadInfo;