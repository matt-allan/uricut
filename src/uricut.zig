const std = @import("std");
const Uri = @import("zuri").Uri;

const UriCutError = error{
    UnknownComponent,
};

// Select parts of the uri_str specified by component_opts and join with delim. Caller owns returned memory.
pub fn uricut(alloc: std.mem.Allocator, uri_str: []const u8, delim: []const u8, component_opts: []const []const u8) ![]u8 {
    const uri = try Uri.parse(uri_str, true);

    var port: []u8 = "";
    defer alloc.free(port);

    var addr: []u8 = "";
    defer alloc.free(addr);

    var components = std.ArrayList([]const u8).init(alloc);
    defer components.clearAndFree();

    for (component_opts) |c| {
        if (std.mem.eql(u8, "scheme", c)) {
            try components.append(uri.scheme);
        } else if (std.mem.eql(u8, "username", c)) {
            try components.append(uri.username);
        } else if (std.mem.eql(u8, "host", c)) {
            switch (uri.host) {
                .name => |name| {
                    try components.append(name);
                },
                .ip => |ip| {
                    addr = try std.fmt.allocPrint(alloc, "{}", .{ip});

                    var end = std.mem.lastIndexOf(u8, addr, ":") orelse addr.len;

                    var host = addr[0..end];

                    try components.append(host);
                },
            }
        } else if (std.mem.eql(u8, "port", c)) {
            if (uri.port != null) {
                port = try std.fmt.allocPrint(alloc, "{}", .{uri.port.?});

                try components.append(port);
            } else {
                try components.append("");
            }
        } else if (std.mem.eql(u8, "path", c)) {
            try components.append(uri.path);
        } else if (std.mem.eql(u8, "query", c)) {
            try components.append(uri.query);
        } else if (std.mem.eql(u8, "fragment", c)) {
            try components.append(uri.fragment);
        } else {
            return UriCutError.UnknownComponent;
        }
    }

    return try std.mem.join(alloc, delim, components.items);
}

test "uricut host" {
    var alloc = std.testing.allocator;

    var output = try uricut(alloc, "https://destructure.co/", " ", &[_][]const u8{
        "host",
    });
    defer alloc.free(output);

    try std.testing.expectEqualStrings("destructure.co", output);
}

test "uricut host and port" {
    var alloc = std.testing.allocator;

    var output = try uricut(alloc, "https://destructure.co/tools/uricut?v=0.1.0", " ", &[_][]const u8{
        "host",
        "port",
    });
    defer alloc.free(output);

    try std.testing.expectEqualStrings("destructure.co 443", output);
}

test "uricut host and port with ipv4 ip" {
    var alloc = std.testing.allocator;

    var output = try uricut(alloc, "127.0.0.1:8080", " ", &[_][]const u8{
        "host",
        "port",
    });
    defer alloc.free(output);

    try std.testing.expectEqualStrings("127.0.0.1 8080", output);
}

test "uricut all" {
    var alloc = std.testing.allocator;

    var output = try uricut(alloc, "https://matt@destructure.co/tools/uricut?v=0.1.0#install", " ", &[_][]const u8{
        "scheme",
        "username",
        "host",
        "port",
        "path",
        "query",
        "fragment",
    });
    defer alloc.free(output);

    try std.testing.expectEqualStrings("https matt destructure.co 443 /tools/uricut v=0.1.0 install", output);
}
