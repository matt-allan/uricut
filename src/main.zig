const std = @import("std");
const Uri = @import("zuri").Uri;
const clap = @import("clap");
const uricut = @import("./uricut.zig").uricut;

const help_text =
    \\ Print selected parts of a URI read from standard input to standard output.
    \\
    \\ The input is expected to be a valid URI as per RFC 3986. The output is the
    \\ parsed URI components, separated by the delimiter. By default all URI
    \\ components are printed, separated by tabs.
    \\
    \\
;
const version = "0.1.0";

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const alloc = arena.allocator();

    var br = std.io.bufferedReader(std.io.getStdIn().reader());
    var stdin = br.reader();
    var bw = std.io.bufferedWriter(std.io.getStdOut().writer());
    var stdout = bw.writer();
    var stderr = std.io.getStdErr().writer();

    const params = comptime clap.parseParamsComptime(
        \\-h, --help                    Display this help and exit.
        \\-c, --component <str>...      Select only these URI components.
        \\-d, --delimiter <str>         Use DELIM instead of tab for field delimiters
        \\
    );

    var diag = clap.Diagnostic{};

    var res = clap.parse(clap.Help, &params, clap.parsers.default, .{
        .diagnostic = &diag,
    }) catch |err| {
        diag.report(stderr, err) catch {};
        return err;
    };

    defer res.deinit();

    if (res.args.help) {
        _ = try stderr.write(help_text);

        try clap.help(stderr, clap.Help, &params, .{});
        return;
    }

    var line = try stdin.readAllAlloc(alloc, 1024 * 5);

    var component_opts = res.args.component;

    if (component_opts.len == 0) {
        component_opts = &[_][]const u8{
            "scheme",
            "username",
            "host",
            "port",
            "path",
            "query",
            "fragment",
        };
    }

    var delim = res.args.delimiter orelse "\t";

    var output = try uricut(alloc, line, delim, component_opts);

    try stdout.print("{s}\n", .{output});

    try bw.flush();
}
