const std = @import("std");

const cubyz = @import("cubyz");
const vec = cubyz.vec;
const Vec2f = vec.Vec2f;
const utils = cubyz.utils;
const BinaryWriter = utils.BinaryWriter;

pub const Alignment = enum(u2) {
	left = 0,
	center = 1,
	right = 2,
};

pub const GuiComponentEnum = enum(u8) {
	button = 0,
	checkBox = 1,
	horizontalList = 2,
	icon = 3,
	itemSlot = 4,
	label = 5,
	scrollBar = 6,
	continuousSlider = 7,
	discreteSlider = 8,
	textInput = 9,
	verticalList = 10,
};

pub const GuiComponent = union(GuiComponentEnum) {
	pub const Button = @import("components/Button.zig");
	pub const CheckBox = @import("components/CheckBox.zig");
	pub const Icon = @import("components/Icon.zig");
	pub const Label = @import("components/Label.zig");
	pub const TextInput = @import("components/TextInput.zig");
	pub const VerticalList = @import("components/VerticalList.zig");

	button: Button,
	checkBox: CheckBox,
	horizontalList: Label,
	icon: Icon,
	itemSlot: Label,
	label: Label,
	scrollBar: Label,
	continuousSlider: Label,
	discreteSlider: Label,
	textInput: TextInput,
	verticalList: VerticalList,

	pub fn deinit(self: GuiComponent) void {
		guiComponentDeinitImpl(self.index());
	}

	pub fn index(self: GuiComponent) u32 {
		switch(self) {
			inline else => |impl| {
				return impl.index;
			},
		}
	}

	pub fn pos(self: GuiComponent) Vec2f {
		var posOut: Vec2f = undefined;
		guiComponentPosImpl(self.index(), &posOut[0], &posOut[1]);
		return posOut;
	}

	pub fn size(self: GuiComponent) Vec2f {
		var sizeOut: Vec2f = undefined;
		guiComponentSizeImpl(self.index(), &sizeOut[0], &sizeOut[1]);
		return sizeOut;
	}
};

pub const AttachmentPoint = enum(u2) {
	lower = 0,
	middle = 1,
	upper = 2,
};

const RelativePositionEnum = enum(u2) {
	ratio = 0,
	attachedToFrame = 1,
	relativeToWindow = 2,
	attachedToWindow = 3,
};

pub const RelativePosition = union(RelativePositionEnum) {
	ratio: f32,
	attachedToFrame: struct {
		selfAttachmentPoint: AttachmentPoint,
		otherAttachmentPoint: AttachmentPoint,
	},
	relativeToWindow: struct {
		otherId: []const u8,
		ratio: f32,
	},
	attachedToWindow: struct {
		otherId: []const u8,
		selfAttachmentPoint: AttachmentPoint,
		otherAttachmentPoint: AttachmentPoint,
	},

	pub fn serialize(self: RelativePosition) []u8 {
		var writer: BinaryWriter = .{};
		writer.writeEnum(RelativePositionEnum, std.meta.activeTag(self));
		switch(self) {
			.ratio => |ratio| {
				writer.writeFloat(f32, ratio);
			},
			.attachedToFrame => |attachedToFrame| {
				writer.writeEnum(AttachmentPoint, attachedToFrame.selfAttachmentPoint);
				writer.writeEnum(AttachmentPoint, attachedToFrame.otherAttachmentPoint);
			},
			.relativeToWindow => |relativeToWindow| {
				writer.writeFloat(f32, relativeToWindow.ratio);
				writer.writeSlice(relativeToWindow.otherId);
			},
			.attachedToWindow => |attachedToWindow| {
				writer.writeEnum(AttachmentPoint, attachedToWindow.selfAttachmentPoint);
				writer.writeEnum(AttachmentPoint, attachedToWindow.otherAttachmentPoint);
				writer.writeSlice(attachedToWindow.otherId);
			},
		}
		return writer.data.items;
	}
};

pub const WindowConfig = struct {
	contentSize: Vec2f,
	scale: f32 = 1,
	spacing: f32 = 0,
	relativePosition: [2]RelativePosition = .{.{.ratio = 0.5}, .{.ratio = 0.5}},
	showTitleBar: bool = true,
	hasBackground: bool = true,
	hideIfMouseIsGrabbed: bool = true,
	closeIfMouseIsGrabbed: bool = false,
	closable: bool = true,
	isHud: bool = false,
};

fn registerWindowConfig(func: anytype, comptime window: *WindowConfig, comptime name: []const u8, comptime id: []const u8) []const u8 {
	const configName = std.fmt.comptimePrint("windowConfig_{s}_{s}", .{name, id});
	@export(&struct {
		fn execute() callconv(.{ .wasm_mvp = .{} }) @typeInfo(@TypeOf(func)).@"fn".return_type.? {
			return func(@field(window, name));
		}
	}.execute, .{.name = configName});
	return configName;
}

fn wrap(func: fn() void) fn() callconv(.{ .wasm_mvp = .{} }) void {
	return struct{
		fn function() callconv(.{ .wasm_mvp = .{} }) void {
			func();
		}
	}.function;
}

pub fn registerWindow(
	comptime windowType: type,
) void {
	const window = windowType.window;
	const name = windowType.id;
	const initName = cubyz.callback.registerCallback(wrap(windowType.init));
	const deinitName = cubyz.callback.registerCallback(wrap(windowType.deinit));
	const onOpenName = cubyz.callback.registerCallback(wrap(windowType.onOpen));
	const onCloseName = cubyz.callback.registerCallback(wrap(windowType.onClose));
	const relativePosX = window.relativePosition[0].serialize();
	const relativePosY = window.relativePosition[1].serialize();
	defer cubyz.allocator.free(relativePosX);
	defer cubyz.allocator.free(relativePosY);
	registerWindowImpl(
		initName.ptr, initName.len,
		deinitName.ptr, deinitName.len,
		onOpenName.ptr, onOpenName.len,
		onCloseName.ptr, onCloseName.len,
		name.ptr, name.len,
		window.contentSize[0], window.contentSize[1],
		window.scale, window.spacing,
		relativePosX.ptr, relativePosX.len,
		relativePosY.ptr, relativePosY.len,
		window.showTitleBar, window.hasBackground,
		window.hideIfMouseIsGrabbed, window.closeIfMouseIsGrabbed,
		window.closable, window.isHud,
	);
}

pub fn setRootComponent(id: []const u8, component: GuiComponent, padding: f32) void {
	setRootComponentImpl(id.ptr, id.len, component.index(), padding);
}

pub fn getRootComponent(id: []const u8) ?GuiComponent {
	var exists: bool = undefined;
	const index = getRootComponentImpl(id.ptr, id.len, &exists);
	if(!exists) return null;
	const typ = getComponentTypeImpl(index);
	return switch(std.meta.stringToEnum(GuiComponentEnum, std.meta.fieldNames(GuiComponent)[typ]).?) {
		inline else => |tag| @unionInit(GuiComponent, @tagName(tag), .{.index = index}),
	};
}

pub fn openWindow(id: []const u8) void {
	openWindowImpl(id.ptr, id.len);
}

pub fn closeWindow(id: []const u8) void {
	closeWindowImpl(id.ptr, id.len);
}

extern fn registerWindowImpl(
	initName: [*]const u8, initNameLen: u32,
	deinitName: [*]const u8, deinitNameLen: u32,
	onOpenName: [*]const u8, onOpenNameLen: u32,
	onCloseName: [*]const u8, onCloseNameLen: u32,
	name: [*]const u8, nameLen: u32,
	contentWidth: f32, contentHeight: f32,
	scale: f32, spacing: f32,
	relativePositionX: [*]const u8, relativePositionXLen: u32,
	relativePositionY: [*]const u8, relativePositionYLen: u32,
	showTitleBar: bool, hasBackground: bool,
	hideIfMouseIsGrabbed: bool, closeIfMouseIsGrabbed: bool,
	closable: bool, isHud: bool,
) void;
extern fn setRootComponentImpl(name: [*]const u8, nameLen: u32, component: u32, padding: f32) void;
extern fn getRootComponentImpl(name: [*]const u8, nameLen: u32, exists: *bool) u32;
extern fn getComponentTypeImpl(index: u32) u8;

extern fn guiComponentPosImpl(index: u32, x: *f32, y: *f32) void;
extern fn guiComponentSizeImpl(index: u32, width: *f32, height: *f32) void;

extern fn guiComponentDeinitImpl(index: u32) void;

extern fn openWindowImpl(idPtr: [*]const u8, idLen: u32) void;
extern fn closeWindowImpl(idPtr: [*]const u8, idLen: u32) void;