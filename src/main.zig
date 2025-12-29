const std = @import("std");
const print = std.debug.print;

pub const c = @cImport({
    @cInclude("objc/NSObjCRuntime.h");
    @cInclude("string.h");
});

extern const NSDefaultRunLoopMode: c.id;

const objc = @import("objc");

var terminated = false;

const NSRect = extern struct {
    origin: extern struct { x: f64, y: f64 },
    size: extern struct { width: f64, height: f64 },
};
const NSPoint = extern struct {
    x: f64,
    y: f64,
};

fn setTerminated(state: bool) void {
    terminated = state;
}

fn setWindowDelegate(window: objc.Object) objc.Object {
    // Window delegate
    const NSObject = objc.getClass("NSObject").?;
    const WindowDelegateClass = objc.allocateClassPair(NSObject, "AppDelegate").?;
    std.debug.assert(WindowDelegateClass.addMethod("windowWillClose:", struct {
        fn imp(target: objc.c.id, sel: objc.c.SEL) callconv(.c) void {
            _ = sel;
            _ = target;
            print("Quitting\n", .{});
            setTerminated(true);
        }
    }.imp));
    _ = objc.registerClassPair(WindowDelegateClass);
    const WindowDelegate = WindowDelegateClass.msgSend(
        objc.Object,
        "alloc",
        .{},
    );
    _ = WindowDelegate.msgSend(
        objc.Object,
        "init",
        .{},
    );
    _ = window.msgSend(void, "setDelegate:", .{WindowDelegate});
    return WindowDelegate;
}

fn createWindowObject(w: f64, h: f64) objc.Object {
    // NSString
    const NSString = objc.getClass("NSString").?;
    const frame = NSRect{
        .origin = .{ .x = 0, .y = 0 },
        .size = .{
            .width = w,
            .height = h,
        },
    };
    const title = NSString.msgSend(
        objc.Object,
        "stringWithUTF8String:",
        .{"snoup from zig"},
    );

    const style: u64 = (1 << 0) | (1 << 1) | (1 << 3); // Style: titled + closable + resizable
    const NSWindow = objc.getClass("NSWindow").?;
    var window = NSWindow.msgSend(objc.Object, "alloc", .{});
    window = window.msgSend(
        objc.Object,
        "initWithContentRect:styleMask:backing:defer:",
        .{
            frame,
            style,
            @as(u64, 2),
            false,
        },
    );
    _ = window.msgSend(void, "center", .{});
    _ = window.msgSend(
        void,
        "setTitle:",
        .{title},
    );
    _ = window.msgSend(
        void,
        "setBackgroundColor:",
        .{objc.getClass("NSColor").?.msgSend(
            objc.Object,
            "blackColor",
            .{},
        )},
    );
    _ = window.msgSend(
        void,
        "makeKeyAndOrderFront:",
        .{@as(?*anyopaque, null)},
    );
    _ = window.msgSend(
        void,
        "setReleasedWhenClosed:",
        .{false},
    );

    _ = setWindowDelegate(window);
    return window;
}

fn createApp() objc.Object {
    const NSAppClass = objc.getClass("NSApplication").?;
    const app = NSAppClass
        .msgSend(
        objc.Object,
        "sharedApplication",
        .{},
    );
    _ = app.msgSend(
        objc.Object,
        "setActivationPolicy:",
        .{@as(isize, 0)},
    );
    _ = app.msgSend(
        objc.Object,
        "activateIgnoringOtherApps:",
        .{true},
    );
    _ = app.msgSend(
        objc.Object,
        "finishLaunching",
        .{},
    );
    return app;
}

fn createMenu(app: objc.Object) void {
    const NSMenu = objc.getClass("NSMenu").?;
    const NSMenuItem = objc.getClass("NSMenuItem").?;

    const menubar = NSMenu.msgSend(objc.Object, "alloc", .{}).msgSend(objc.Object, "init", .{});
    const appMenuItem = NSMenuItem.msgSend(objc.Object, "alloc", .{}).msgSend(objc.Object, "init", .{});
    _ = menubar.msgSend(void, "addItem:", .{appMenuItem});
    _ = app.msgSend(void, "setMainMenu:", .{menubar});
}

fn createButton() objc.Object {
    const NSButtonClass = objc.getClass("NSButton").?;
    const frame = NSRect{
        .origin = .{ .x = 0, .y = 0 },
        .size = .{
            .width = 100,
            .height = 100,
        },
    };
    const button = NSButtonClass.msgSend(objc.Object, "alloc", .{})
        .msgSend(objc.Object, "initWithFrame:", .{frame});
    _ = button.msgSend(void, "setButtonType:", .{0});
    _ = button.msgSend(void, "setBordered:", .{true});
    _ = button.msgSend(void, "setBezelColor:", .{objc.getClass("NSColor").?.msgSend(
        objc.Object,
        "whiteColor",
        .{},
    )});
    _ = button.msgSend(void, "setBezelStyle:", .{@as(u64, 1)});
    _ = button.msgSend(void, "setContentTintColor:", .{objc.getClass("NSColor").?.msgSend(
        objc.Object,
        "whiteColor",
        .{},
    )});
    _ = button.msgSend(void, "setTitle:", .{objc.getClass("NSString").?.msgSend(
        objc.Object,
        "stringWithUTF8String:",
        .{"button !"},
    )});
    return button;
}

pub fn main() !void {
    // Release Pool
    const NSAutoreleasePoolClass = objc.getClass("NSAutoreleasePool").?;
    const poolAlloc = NSAutoreleasePoolClass.msgSend(objc.Object, "alloc", .{});
    const pool = poolAlloc.msgSend(objc.Object, "init", .{});
    defer _ = pool.msgSend(objc.Object, "drain", .{});

    // APP
    const app = createApp();
    defer _ = app.msgSend(void, "autorelease", .{});

    // Menu, mandatory for creating a "native" app
    createMenu(app);

    // Window
    const window = createWindowObject(800, 600);
    defer _ = window.msgSend(void, "autorelease", .{});

    // Distant future (block event loop)
    const DateClass = objc.getClass("NSDate").?;
    const distantFuture = DateClass.msgSend(objc.Object, "distantFuture", .{});
    defer _ = distantFuture.msgSend(void, "autorelease", .{});

    // BUTTON
    const button = createButton();

    // Get and set the button to the contentView
    const contentView = window.msgSend(objc.Object, "contentView", .{});
    _ = contentView.msgSend(void, "addSubview:", .{button});

    while (!terminated) {
        // This will instanciate the window and wait for any event
        const event = app.msgSend(
            objc.Object,
            "nextEventMatchingMask:untilDate:inMode:dequeue:",
            .{
                c.NSUIntegerMax,
                distantFuture,
                NSDefaultRunLoopMode,
                true,
            },
        );
        const eventType = event.msgSend(
            c.NSUInteger,
            "type",
            .{},
        );
        switch (eventType) {
            // LeftMouseDown
            1 => {
                print("mouse left key down\n", .{});
            },
            // RightMouseDown
            3 => {
                print("right mouse key down\n", .{});
                setTerminated(true);
            },
            // KeyDown:
            10 => {
                const inputText = event.msgSend(objc.Object, "characters", .{});
                const inputTextUTF8 = inputText.msgSend([*:0]const u8, "UTF8String", .{});
                const keyCode = event.msgSend(c.uint_fast16_t, "keyCode", .{});
                print("key down {}, text '{s}'\n", .{ keyCode, inputTextUTF8 });
            },
            else => {
                // print("event: {*}", .{eventType});
            },
        }
        // forward the event to the window
        _ = app.msgSend(void, "sendEvent:", .{event});
        _ = app.msgSend(void, "updateWindows", .{});
    }
}
