const std = @import("std");

const cubyz = @import("cubyz");
const world = cubyz.world;
const Block = world.Block;
const Neighbor = world.Neighbor;
const models = cubyz.models;
const Model = models.Model;
const rotation = cubyz.rotation;
const Degrees = rotation.Degrees;
const vec = cubyz.vec;
const Mat4f = vec.Mat4f;
const Vec3f = vec.Vec3f;
const Vec3i = vec.Vec3i;
const ZonElement = cubyz.zon.ZonElement;

var rotatedModels: std.StringHashMap(Model) = undefined;

pub const id = "mymod:custom_dir";

pub fn init() void {
	rotatedModels = .init(cubyz.allocator);
}

pub fn deinit() void {
	rotatedModels.deinit();
}

pub fn reset() void {
	rotatedModels.clearRetainingCapacity();
}

pub fn createBlockModel(_: Block, _: *u16, zon: ZonElement) Model {
	const modelId = zon.as([]const u8, "cubyz:cube");
	if(rotatedModels.get(modelId)) |modelIndex| return modelIndex;

	const baseModel = Model.getModelFromId(modelId);
	// Rotate the model:
	const modelIndex = baseModel.transformModel(rotation.rotationMatrixTransform, .{Mat4f.identity()});
	_ = baseModel.transformModel(rotation.rotationMatrixTransform, .{Mat4f.rotationY(std.math.pi)});
	_ = baseModel.transformModel(rotation.rotationMatrixTransform, .{Mat4f.rotationZ(-std.math.pi/2.0).mul(Mat4f.rotationX(-std.math.pi/2.0))});
	_ = baseModel.transformModel(rotation.rotationMatrixTransform, .{Mat4f.rotationZ(std.math.pi/2.0).mul(Mat4f.rotationX(-std.math.pi/2.0))});
	_ = baseModel.transformModel(rotation.rotationMatrixTransform, .{Mat4f.rotationX(-std.math.pi/2.0)});
	_ = baseModel.transformModel(rotation.rotationMatrixTransform, .{Mat4f.rotationZ(std.math.pi).mul(Mat4f.rotationX(-std.math.pi/2.0))});
	rotatedModels.put(modelId, modelIndex) catch unreachable;
	return modelIndex;
}

pub fn model(block: Block) Model {
	return block.modelIndexStart().offset(@min(block.data, 5));
}

pub fn rotateZ(data: u16, angle: Degrees) u16 {
	comptime var rotationTable: [4][6]u8 = undefined;
	comptime for(0..6) |i| {
		rotationTable[0][i] = i;
	};
	comptime for(1..4) |a| {
		for(0..6) |i| {
			const neighbor: Neighbor = @enumFromInt(rotationTable[a - 1][i]);
			rotationTable[a][i] = neighbor.rotateZ().toInt();
		}
	};
	if(data >= 6) return 0;
	const runtimeTable = rotationTable;
	return runtimeTable[@intFromEnum(angle)][data];
}

pub fn generateData(_: Vec3i, _: Vec3f, _: Vec3f, _: Vec3i, neighbor: ?Neighbor, currentData: *Block, _: Block, blockPlacing: bool) bool {
	if(blockPlacing) {
		cubyz.chat.showMessage("{d} {s}\n", .{@intFromEnum(neighbor.?), @tagName(neighbor.?)});
		currentData.data = neighbor.?.reverse().toInt();
		return true;
	}
	return false;
}