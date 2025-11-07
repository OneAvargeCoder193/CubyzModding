const cubyz = @import("cubyz");
const vec = cubyz.vec;
const Vec2f = vec.Vec2f;

const gui = cubyz.gui;
const GuiComponent = gui.GuiComponent;

const TextInput = @This();

index: u32,

const OptionalCallbacks = struct {
	onUp: ?fn() void = null,
	onDown: ?fn() void = null,
};

pub fn init(pos: Vec2f, maxWidth: f32, maxHeight: f32, text: []const u8, onNewline: fn() void, optional: OptionalCallbacks) TextInput {
	const callbackName = cubyz.callback.registerCallback(struct{
		fn wrap(_: u32) callconv(.{ .wasm_mvp = .{} }) void {
			return onNewline();
		}
	}.wrap);
	const onUpName = cubyz.callback.registerCallback(struct{
		fn wrap(_: u32) callconv(.{ .wasm_mvp = .{} }) void {
			if(optional.onUp == null) return;
			return optional.onUp.?();
		}
	}.wrap);
	const onDownName = cubyz.callback.registerCallback(struct{
		fn wrap(_: u32) callconv(.{ .wasm_mvp = .{} }) void {
			if(optional.onDown == null) return;
			return optional.onDown.?();
		}
	}.wrap);
	return .{
		.index = initTextInputImpl(pos[0], pos[1], maxWidth, maxHeight, text.ptr, text.len, callbackName.ptr, callbackName.len, onUpName.ptr, onUpName.len, onDownName.ptr, onDownName.len),
	};
}

pub fn deinit(self: TextInput) void {
	self.toComponent().deinit();
}

pub fn toComponent(self: TextInput) GuiComponent {
	return .{.textInput = self};
}

pub fn clear(self: TextInput) void {
	clearTextInputImpl(self.index);
}

pub fn setText(self: TextInput, text: []const u8) void {
	setTextInputImpl(self.index, text.ptr, text.len);
}

extern fn initTextInputImpl(posX: f32, posY: f32, maxWidth: f32, maxHeight: f32, textPtr: [*]const u8, textLen: u32, onNewlinePtr: [*]const u8, onNewlineLen: u32, onUpPtr: [*]const u8, onUpLen: u32, onDownPtr: [*]const u8, onDownLen: u32) u32;
extern fn clearTextInputImpl(index: u32) void;
extern fn setTextInputImpl(index: u32, textPtr: [*]const u8, textLen: u32) void;