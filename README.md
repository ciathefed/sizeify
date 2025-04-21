# sizeify

Format byte sizes into human-readable strings using multiple scale types. Supports decimal (SI), binary (IEC), and Windows-style units.

Inspired by the [humansize](https://crates.io/crates/humansize) crate from the Rust ecosystem.

Written in [Zig](https://ziglang.org/). No dependencies.

## Features

- Decimal (SI): `kB`, `MB`, `GB`, etc. (base 1000)
- Binary (IEC): `KiB`, `MiB`, `GiB`, etc. (base 1024)
- Windows-style: `KB`, `MB`, `GB`, etc. (base 1024, but uses SI labels)
- Both short and long unit names
- Works with fixed buffers, writers, or allocators
- Accurate rounding to two decimal places

## Install

Run this command in the root of your Zig project:

```shell
zig fetch --save "git+https://github.com/ciathefed/sizeify"
```

Add this snippet to your `build.zig`:

```zig
const sizeify = b.dependency("sizeify", .{
    .target = target,
    .optimize = optimize,
});
exe_mod.addImport("sizeify", sizeify.module("sizeify"));
```

## Usage

```zig
const sizeify = @import("sizeify");

const formatted = try sizeify.formatAlloc(1536, .binary_short, allocator);
// formatted == "1.50 KiB"
```

Also available:

- `formatBuf(size, scale, buffer)`
- `formatAlloc(size, scale, allocator)`
- `formatWriter(size, scale, writer)`

## Output Examples

| Bytes     | Scale              | Output          |
|-----------|--------------------|-----------------|
| 0         | decimal_short       | `0.00 B`        |
| 1500      | decimal_short       | `1.50 kB`       |
| 1024      | binary_long         | `1.00 Kibibytes`|
| 1024      | windows_short       | `1.00 KB`       |
| max usize | decimal_short       | `18.45 EB` (on 64-bit) |

## Testing

Run with:

```sh
zig build test
```

## License

This project is licensed under the [MIT License](./LICENSE)
