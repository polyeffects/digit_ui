# Adding Modules to Beebo

The modules on Beebo are [LV2 plugins](https://lv2plug.in/).
These plugins are "bundles", directories
with one or more software libraries
and one or more [turtle files](https://www.w3.org/TR/turtle/)
to describe the software.

LV2 plugins are written in a programming language
that can be compiled to native code.
This document follows the example of an LV2 plugin,
[straggli](https://github.com/ecashin/straggli),
which is written in [Rust](https://www.rust-lang.org/).

## Compiling the LV2 Plugin

The [rust lv2 crate](https://docs.rs/lv2/latest/lv2/)
is a Rust library ("crate") that handles most of the LV2 plugin
boilerplate code.

As of January 2022, the version from the git repository
was needed to provide recently added support for in-place buffer operations.
In-place functionality allows testing in [Ardour](https://ardour.org/),
an open-source digital audio workstation (DAW).

The lines below add the lv2 crates to straggli's `dependencies` section,
in its [Cargo.toml](https://github.com/ecashin/straggli/blob/main/Cargo.toml) file.

    lv2 = { git = "https://github.com/RustAudio/rust-lv2.git" }
    lv2-core = { git = "https://github.com/RustAudio/rust-lv2.git" }

This example covers plugin builds on Linux.

## Development

The library files are built with the command, `cargo build`,
for the host running `cargo`.
In a moment we'll describe how to cross compile for Beemo.
After building the shared library (`.so`) file,
the file is copied to the bundle directory where the `.ttl` files appear.

This bundle directory is copied to the location where your audio application
scans for plugins.

## Compiling for Beebo

The Beebo hardware is `aarch64` architecture.
You'll need a toolchain
for [cross compiling](https://wiki.pine64.org/wiki/Cross-compiling)
for `aarch64`,
unless that's already your architecture.

It's [relatively easy in Rust](https://github.com/japaric/rust-cross)
to add most of what you need with `rustup`.

    rustup add aarch64-unknown-linux-gnu

You will still need a linker, though, so check your Linux distribution
for a toolchain.
On Ubuntu, the command below provides a linker.

    sudo apt install gcc-aarch64-linux-gnu

It is necessary to inform `cargo` about the linker.

    mkdir -p ~/.cargo
    cat >>~/.cargo/config <<EOF

    [target.aarch64-unknown-linux-gnu]
    linker = "aarch64-linux-gnu-gcc"
    EOF

Now the plugin is built for Beebo when you specify the target architecture
as shown below.
Make sure to use the new `.so` file for `aarch64`.

    cargo build --target=aarch64-unknown-linux-gnu \
      && cp target/aarch64-unknown-linux-gnu/debug/libstraggli.so straggli.lv2/

## Accessing Beebo

When Beebo boots with a USB ethernet dongle attached,
it uses DHCP to attempt to acquire an IP address.
You can see the IP address by going to settings,
pressing "QA Test", and then pressing, "IP".

Caution: Running a DHCP server on a network
where hosts are already trying to communicate
can interfere with the whole network.
That said, one way to support Beebo's networking
is to shut down Network Manager on your machine
and use a cat 6 cable
from your machine to Beebo.
In that situation you can manually configure
your machine's ethernet interface
and configure a DHCP server (like udhcpd)
to provide an address to Beebo over the cable.

Once Beebo gets an address, you can ssh from your machine
to Beebo as the `debian` user.
You can email Poly Effects for the password.

## Updating the Module List

The [module_info.py](module_info.py) file contains information about all
of the modules displayed in the Beebo UI.
For your new module to appear, it must be in `module_info.py`.

Example changes appear in [add-module/straggli.diff](add-module/straggli.diff).

## Modifying Beebo

A potential source of confusion is Beebo's overlay filesystem.
If you place files in user debian's home directory and reboot,
for example, the files will not be there after the reboot.

Although in general it is not recommended to modify the
"lower" read-only filesystem underlying an overlay filesystem,
the commands below seem to work for the installation
of a new plugin.
Only do this if you do not mind the (small) risk
of corrupting your Beebo's filesystem and requiring a repair.

    debian@pine64so:~$ sudo mount -o remount,rw /media/root-ro/overlay/lower/
    debian@pine64so:~$ sudo cp module_info.py /media/root-ro/overlay/lower/home/debian/UI
    debian@pine64so:~$ sync
    debian@pine64so:~$ sudo rsync -av straggli.lv2 /media/root-ro/overlay/lower/usr/lib/lv2/
    debian@pine64so:~$ sync

After rebooting Beebo, you should see your `aarch64`-architecture plugin
in the place where Beebo scans for plugins.

    debian@pine64so:~$ file /usr/lib/lv2/straggli.lv2/libstraggli.so 
    /usr/lib/lv2/straggli.lv2/libstraggli.so: ELF 64-bit LSB shared object, x86-64, version 1 (SYSV), dynamically linked, BuildID[sha1]=67398ff70557d72c9fc892be28d3fccbfa70df93, not stripped
    debian@pine64so:~$ 

## Enjoy

Enjoy!
