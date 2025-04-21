const std = @import("std");

const scale_size = 9;

const decimal_scales_short: [scale_size][]const u8 = .{
    "B", "kB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB",
};
const binary_scales_short: [scale_size][]const u8 = .{
    "B", "KiB", "MiB", "GiB", "TiB", "PiB", "EiB", "ZiB", "YiB",
};
const windows_scales_short: [scale_size][]const u8 = .{
    "B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB",
};

const decimal_scales_long: [scale_size][]const u8 = .{
    "Bytes",     "Kilobytes", "Megabytes",  "Gigabytes",  "Terabytes",
    "Petabytes", "Exabytes",  "Zettabytes", "Yottabytes",
};
const binary_scales_long: [scale_size][]const u8 = .{
    "Bytes",     "Kibibytes", "Mebibytes", "Gibibytes", "Tebibytes",
    "Pebibytes", "Exbibytes", "Zebibytes", "Yobibytes",
};
const windows_scales_long: [scale_size][]const u8 = .{
    "Bytes",     "Kilobytes", "Megabytes",  "Gigabytes",  "Terabytes",
    "Petabytes", "Exabytes",  "Zettabytes", "Yottabytes",
};

/// Enum defining the available scale formats
pub const Scale = enum {
    decimal_short,
    decimal_long,
    binary_short,
    binary_long,
    windows_short,
    windows_long,
};

fn getDivisor(scale: Scale) f64 {
    return switch (scale) {
        .decimal_short, .decimal_long => 1000,
        .binary_short, .binary_long, .windows_short, .windows_long => 1024,
    };
}

fn getScales(scale: Scale) [scale_size][]const u8 {
    return switch (scale) {
        .decimal_short => decimal_scales_short,
        .decimal_long => decimal_scales_long,
        .binary_short => binary_scales_short,
        .binary_long => binary_scales_long,
        .windows_short => windows_scales_short,
        .windows_long => windows_scales_long,
    };
}

/// Formats a byte size into a human-readable string and writes into a user-provided buffer
pub fn formatBuf(size: usize, scale: Scale, buffer: []u8) ![]u8 {
    const divisor = getDivisor(scale);
    const scales = getScales(scale);

    var val = @as(f64, @floatFromInt(size));
    var i: usize = 0;
    while (val >= divisor and i + 1 < scale_size) : (i += 1) {
        val /= divisor;
    }

    return std.fmt.bufPrint(buffer, "{d:.2} {s}", .{ val, scales[i] });
}

/// Formats a byte size into a human-readable string using an allocator
pub fn formatAlloc(size: usize, scale: Scale, allocator: std.mem.Allocator) ![]u8 {
    const divisor = getDivisor(scale);
    const scales = getScales(scale);

    var val = @as(f64, @floatFromInt(size));
    var i: usize = 0;
    while (val >= divisor and i + 1 < scale_size) : (i += 1) {
        val /= divisor;
    }

    return std.fmt.allocPrint(allocator, "{d:.2} {s}", .{ val, scales[i] });
}

/// Formats a byte size into a human-readable string and writes it to a generic writer
pub fn formatWriter(size: usize, scale: Scale, writer: anytype) !void {
    const divisor = getDivisor(scale);
    const scales = getScales(scale);

    var val = @as(f64, @floatFromInt(size));
    var i: usize = 0;
    while (val >= divisor and i + 1 < scale_size) : (i += 1) {
        val /= divisor;
    }

    try writer.print("{d:.2} {s}", .{ val, scales[i] });
}

const testing = std.testing;

test "format bytes - decimal short" {
    const cases = .{
        .{ .size = 0, .expected = "0.00 B" },
        .{ .size = 1, .expected = "1.00 B" },
        .{ .size = 999, .expected = "999.00 B" },
        .{ .size = 1000, .expected = "1.00 kB" },
        .{ .size = 1500, .expected = "1.50 kB" },
        .{ .size = 999_999, .expected = "1000.00 kB" },
        .{ .size = 1_000_000, .expected = "1.00 MB" },
        .{ .size = 1_500_000, .expected = "1.50 MB" },
    };

    inline for (cases) |case| {
        var buf: [32]u8 = undefined;
        const res = try formatBuf(case.size, .decimal_short, &buf);
        try testing.expectEqualStrings(case.expected, res);
    }
}

test "format bytes - binary long" {
    const cases = .{
        .{ .size = 0, .expected = "0.00 Bytes" },
        .{ .size = 1023, .expected = "1023.00 Bytes" },
        .{ .size = 1024, .expected = "1.00 Kibibytes" },
        .{ .size = 1536, .expected = "1.50 Kibibytes" },
        .{ .size = 1024 * 1024 - 1, .expected = "1024.00 Kibibytes" },
        .{ .size = 1024 * 1024, .expected = "1.00 Mebibytes" },
    };

    inline for (cases) |case| {
        var buf: [32]u8 = undefined;
        const res = try formatBuf(case.size, .binary_long, &buf);
        try testing.expectEqualStrings(case.expected, res);
    }
}

test "format bytes - windows short" {
    const cases = .{
        .{ .size = 0, .expected = "0.00 B" },
        .{ .size = 1023, .expected = "1023.00 B" },
        .{ .size = 1024, .expected = "1.00 KB" },
        .{ .size = 1536, .expected = "1.50 KB" },
    };

    inline for (cases) |case| {
        var buf: [32]u8 = undefined;
        const res = try formatBuf(case.size, .windows_short, &buf);
        try testing.expectEqualStrings(case.expected, res);
    }
}

test "formatBuf - binary short" {
    var buf: [32]u8 = undefined;
    const res = try formatBuf(2048, .binary_short, &buf);
    try testing.expectEqualStrings("2.00 KiB", res);
}

test "formatAlloc" {
    const allocator = testing.allocator;
    const res = try formatAlloc(1500, .decimal_short, allocator);
    defer allocator.free(res);
    try testing.expectEqualStrings("1.50 kB", res);
}

test "formatWriter" {
    var buffer: [64]u8 = undefined;
    var stream = std.io.fixedBufferStream(&buffer);
    try formatWriter(1500, .decimal_long, stream.writer());

    const expected = "1.50 Kilobytes";
    const written = stream.getWritten();
    try testing.expectEqualStrings(expected, written);
}

test "edge cases" {
    const allocator = testing.allocator;

    const max_size = std.math.maxInt(usize);
    const res = try formatAlloc(max_size, .decimal_short, allocator);
    defer allocator.free(res);

    try testing.expect(std.mem.endsWith(u8, res, " EB"));
}
