const cubyz = @import("cubyz");
const vec = cubyz.vec;
const Vec2f = vec.Vec2f;

const gui = cubyz.gui;
const GuiComponent = gui.GuiComponent;

const CheckBox = @This();

index: u32,

pub fn init(pos: Vec2f, width: f32, text: []const u8, initialValue: bool, callback: fn(bool) void) CheckBox {
	const callbackName = cubyz.callback.registerCallback(callback, struct{
		fn wrap(func: fn(bool) void) fn(bool) callconv(.{ .wasm_mvp = .{} }) void {
			return struct{
				fn function(arg: bool) callconv(.{ .wasm_mvp = .{} }) void {
					return func(arg);
				}
			}.function;
		}
	}.wrap);
	return .{
		.index = initCheckBoxImpl(pos[0], pos[1], width, text.ptr, @intCast(text.len), initialValue, callbackName.ptr, @intCast(callbackName.len)),
	};
}

pub fn deinit(self: CheckBox) void {
	self.toComponent().deinit();
}

pub fn toComponent(self: CheckBox) GuiComponent {
	return .{.checkBox = self};
}

extern fn initCheckBoxImpl(posX: f32, posY: f32, width: f32, textPtr: [*]const u8, textLen: u32, initialValue: bool, callbackPtr: [*]const u8, callbackLen: u32) u32;