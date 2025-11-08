const cubyz = @import("cubyz");
const callback = cubyz.callback;
const world = cubyz.world;
const Block = world.Block;
const Neighbor = world.Neighbor;
const models = cubyz.models;
const Model = models.Model;
const QuadInfo = models.QuadInfo;
const ZonElement = cubyz.zon.ZonElement;
const items = cubyz.items;
const Item = items.Item;
const ItemStack = items.ItemStack;
const vec = cubyz.vec;
const Mat4f = vec.Mat4f;
const Vec3f = vec.Vec3f;

pub const Degrees = enum(u2) {
	@"0" = 0,
	@"90" = 1,
	@"180" = 2,
	@"270" = 3,
};

pub fn rotationMatrixTransform(quad: QuadInfo, transformMatrix: Mat4f) void {
	quad.setNormal(vec.xyz(Mat4f.mulVec(transformMatrix, vec.combine(quad.normal(), 0))));
	for(0..4) |i| {
		quad.setCorner(i, vec.xyz(Mat4f.mulVec(transformMatrix, vec.combine(quad.corner(i) - Vec3f{0.5, 0.5, 0.5}, 1))) + Vec3f{0.5, 0.5, 0.5});
	}
}

pub const CanBeChangedInto = union(enum(u3)) {
	no: void,
	yes: void,
	yes_costsDurability: u16,
	yes_costsItems: u16,
	yes_dropsItems: u16,
};

pub fn registerRotationMode(comptime rotationType: type) void {
	const init = callback.registerCallback(struct{
		fn wrap() callconv(.{ .wasm_mvp = .{} }) void {
			rotationType.init();
		}
	}.wrap);
	const deinit = callback.registerCallback(struct{
		fn wrap() callconv(.{ .wasm_mvp = .{} }) void {
			rotationType.deinit();
		}
	}.wrap);
	const reset = callback.registerCallback(struct{
		fn wrap() callconv(.{ .wasm_mvp = .{} }) void {
			rotationType.reset();
		}
	}.wrap);
	const model = if(@hasDecl(rotationType, "model")) callback.registerCallback(struct{
		fn wrap(block: Block) callconv(.{ .wasm_mvp = .{} }) Model {
			return rotationType.model(block);
		}
	}.wrap) else "";
	const rotateZ = if(@hasDecl(rotationType, "rotateZ")) callback.registerCallback(struct{
		fn wrap(data: u16, angle: u32) callconv(.{ .wasm_mvp = .{} }) u16 {
			return rotationType.rotateZ(data, @enumFromInt(angle));
		}
	}.wrap) else "";
	const createBlockModel = if(@hasDecl(rotationType, "createBlockModel")) callback.registerCallback(struct{
		fn wrap(block: Block, modeData: *u16, zonPtr: [*]const u8, zonLen: u32) callconv(.{ .wasm_mvp = .{} }) Model {
			const zon = ZonElement.parseFromString(zonPtr[0..zonLen]);
			defer zon.deinit();
			return rotationType.createBlockModel(block, modeData, zon);
		}
	}.wrap) else "";
	const generateData = if(@hasDecl(rotationType, "generateData")) callback.registerCallback(struct{
		fn wrap(posX: i32, posY: i32, posZ: i32, relPosX: f32, relPosY: f32, relPosZ: f32, playerDirX: f32, playerDirY: f32, playerDirZ: f32, relDirX: i32, relDirY: i32, relDirZ: i32, neighborExists: bool, neighbor: u32, currentData: *Block, neighborBlock: Block, blockPlacing: bool) callconv(.{ .wasm_mvp = .{} }) bool {
			return rotationType.generateData(.{posX, posY, posZ}, .{relPosX, relPosY, relPosZ}, .{playerDirX, playerDirY, playerDirZ}, .{relDirX, relDirY, relDirZ}, if(neighborExists) @enumFromInt(neighbor) else null, currentData, neighborBlock, blockPlacing);
		}
	}.wrap) else "";
	const updateData = if(@hasDecl(rotationType, "updateData")) callback.registerCallback(struct{
		fn wrap(block: *Block, neighbor: Neighbor, neighborBlock: Block) callconv(.{ .wasm_mvp = .{} }) bool {
			return rotationType.updateData(block, neighbor, neighborBlock);
		}
	}.wrap) else "";
	const modifyBlock = if(@hasDecl(rotationType, "modifyBlock")) callback.registerCallback(struct{
		fn wrap(block: *Block, newType: u16) callconv(.{ .wasm_mvp = .{} }) bool {
			return rotationType.modifyBlock(block, newType);
		}
	}.wrap) else "";
	const rayIntersection = if(@hasDecl(rotationType, "rayIntersection")) callback.registerCallback(struct{
		fn wrap(block: Block, itemExists: bool, item: Item, relativePlayerPosX: f32, relativePlayerPosY: f32, relativePlayerPosZ: f32, playerDirX: f32, playerDirY: f32, playerDirZ: f32, distance: *f64, minX: *f32, minY: *f32, minZ: *f32, maxX: *f32, maxY: *f32, maxZ: *f32, face: *Neighbor) callconv(.{ .wasm_mvp = .{} }) void {
			_ = block;
			_ = itemExists;
			_ = item;
			_ = relativePlayerPosX;
			_ = relativePlayerPosY;
			_ = relativePlayerPosZ;
			_ = playerDirX;
			_ = playerDirY;
			_ = playerDirZ;
			_ = distance;
			_ = minX;
			_ = minY;
			_ = minZ;
			_ = maxX;
			_ = maxY;
			_ = maxZ;
			_ = face;
			@compileError("rayIntersection is not implemented yet.");
			// const res = rotationType.rayIntersection(block, if(itemExists) item else null, .{relativePlayerPosX, relativePlayerPosY, relativePlayerPosZ}, .{playerDirX}, .{playerDirY}, .{playerDirZ});
			// distance.* = res.distance;
			// minX.* = res.min[0];
			// minY.* = res.min[1];
			// minZ.* = res.min[2];
			// maxX.* = res.max[0];
			// maxY.* = res.max[1];
			// maxZ.* = res.max[2];
			// face.* = res.face;
		}
	}.wrap) else "";
	const onBlockBreaking = if(@hasDecl(rotationType, "onBlockBreaking")) callback.registerCallback(struct{
		fn wrap(itemExists: bool, item: Item, relativePlayerPosX: f32, relativePlayerPosY: f32, relativePlayerPosZ: f32, playerDirX: f32, playerDirY: f32, playerDirZ: f32, block: *Block) callconv(.{ .wasm_mvp = .{} }) bool {
			_ = itemExists;
			_ = item;
			_ = relativePlayerPosX;
			_ = relativePlayerPosY;
			_ = relativePlayerPosZ;
			_ = playerDirX;
			_ = playerDirY;
			_ = playerDirZ;
			_ = block;
			@compileError("onBlockBreaking is not implemented yet.");
		}
	}.wrap) else "";
	const canBeChangedInto = if(@hasDecl(rotationType, "canBeChangedInto")) callback.registerCallback(struct{
		fn wrap(oldBlock: Block, newBlock: Block, item: ItemStack, shouldDropSourceBlockOnSuccess: *bool) callconv(.{ .wasm_mvp = .{} }) extern struct{typ: u32, val: u16} {
			_ = oldBlock;
			_ = newBlock;
			_ = item;
			_ = shouldDropSourceBlockOnSuccess;
			@compileError("canBeChangedInto is not implemented yet.");
		}
	}.wrap) else "";
	const getBlockTags = if(@hasDecl(rotationType, "getBlockTags")) callback.registerCallback(struct{
		fn wrap() callconv(.{ .wasm_mvp = .{} }) extern struct{ptr: [*]const struct{ptr: [*]const u8, len: u32}, len: u32} {
			@compileError("getBlockTags is not implemented yet.");
		}
	}.wrap) else "";
	registerRotationModeImpl(
		rotationType.id.ptr, rotationType.id.len,
		@hasDecl(rotationType, "dependsOnNeighbors"), if(@hasDecl(rotationType, "dependsOnNeighbors")) @field(rotationType, "dependsOnNeighbors") else false,
		@hasDecl(rotationType, "naturalStandard"), if(@hasDecl(rotationType, "naturalStandard")) @field(rotationType, "naturalStandard") else 0,
		init.ptr, init.len,
		deinit.ptr, deinit.len,
		reset.ptr, reset.len,
		model.ptr, model.len,
		rotateZ.ptr, rotateZ.len,
		createBlockModel.ptr, createBlockModel.len,
		generateData.ptr, generateData.len,
		updateData.ptr, updateData.len,
		modifyBlock.ptr, modifyBlock.len,
		rayIntersection.ptr, rayIntersection.len,
		onBlockBreaking.ptr, onBlockBreaking.len,
		canBeChangedInto.ptr, canBeChangedInto.len,
		getBlockTags.ptr, getBlockTags.len,
	);
}

extern fn registerRotationModeImpl(
	idPtr: [*]const u8, idLen: u32,
	dependsOnNeighborsExists: bool, dependsOnNeighbors: bool,
	naturalStandardExists: bool, naturalStandard: u16,
	initPtr: [*]const u8, initLen: u32,
	deinitPtr: [*]const u8, deinitLen: u32,
	resetPtr: [*]const u8, resetLen: u32,
	modelPtr: [*]const u8, modelLen: u32,
	rotateZPtr: [*]const u8, rotateZLen: u32,
	createBlockModelPtr: [*]const u8, createBlockModelLen: u32,
	generateDataPtr: [*]const u8, generateDataLen: u32,
	updateDataPtr: [*]const u8, updateDataLen: u32,
	modifyBlockPtr: [*]const u8, modifyBlockLen: u32,
	rayIntersectionPtr: [*]const u8, rayIntersectionLen: u32,
	onBlockBreakingPtr: [*]const u8, onBlockBreakingLen: u32,
	canBeChangedIntoPtr: [*]const u8, canBeChangedIntoLen: u32,
	getBlockTagsPtr: [*]const u8, getBlockTagsLen: u32,
) void;