# Toolchain – clang, libc++, libc

The executables are dynamically linked against libc++ and libc. The dynamic linker
is */System/Libraries/libc.so*, it searches for the needed libraries in its own
directory.

There are no configuration files or other search paths, apart from LD_LIBRARY_PATH
support for debugging.

## Libraries
```console
[/]$ tree /System/Libraries/
|-- libc++.so
`-- libc.so
```

```console
[/]$ readelf -d /System/Libraries/libc++.so
Dynamic section at offset 0x14e4f0 contains 23 entries:
  Tag                Type           Name/Value
  0x0000000000000001 (NEEDED)       Shared library: [libc.so]
  0x000000000000000e (SONAME)       Library soname: [libc++.so]
```

## Binaries – the dynamic loader / INTERP is *libc.so*
```console
[/]$ echo 'int main() {return 0;}' > test.cpp
[/]$ clang++ -Wall test.cpp -o test
[/]$ readelf -d test
Dynamic section at offset 0x770 contains 24 entries:
  Tag                Type           Name/Value
  0x0000000000000001 (NEEDED)       Shared library: [libc++.so]
  0x0000000000000001 (NEEDED)       Shared library: [libc.so]


[/]$ readelf -l test

Elf file type is DYN (Shared object file)
Entry point 0x105b8
There are 10 program headers, starting at offset 64

Program Headers:
  Type           Offset   VirtAddr           PhysAddr           FileSiz  MemSiz   Flg Align
  PHDR           0x000040 0x0000000000000040 0x0000000000000040 0x000230 0x000230 R   0x8
  INTERP         0x000270 0x0000000000000270 0x0000000000000270 0x00001a 0x00001a R   0x1
      [Requesting program interpreter: /System/Libraries/libc.so]


[/]$ readelf -p .comment test

String dump of section '.comment':
[     1] clang version 20.1.1 (WebThing 937bcabfa8d1)
[    2e] Linker: LLD 20.1.1 (WebThing 937bcabfa8d1)
```

## Compiler
```console
[/]$ clang++ -v
clang version 20.1.1 (WebThing 937bcabfa8d1)
Target: aarch64-webthing-linux
Thread model: posix
InstalledDir: /System/bin
Configuration file: /System/etc/aarch64-webthing-linux-clang++.cfg
System configuration file directory: /System/etc
```

## Root
```console
[Origin]$ ./chroot.sh
[/]$ echo $$
1

[/]$ ls -la /
total 32
drwxr-xr-x   1     0     0  136 Mar 15 20:52 .
drwxr-xr-x   1     0     0  136 Mar 15 20:52 ..
-rw-r--r--   1     0     0   79 Mar 15 20:30 .bashrc
drwxr-xr-x   1     0     0  236 Mar 15 20:45 Origin
drwxr-xr-x   1     0     0  160 Mar 15 20:50 System
lrwxrwxrwx   1     0     0    7 Mar 15 20:30 bin -> usr/bin
drwxr-xr-x   1     0     0   22 Mar 15 20:46 dev
lrwxrwxrwx   1     0     0    7 Mar 15 20:30 lib -> usr/lib
lrwxrwxrwx   1     0     0    9 Mar 15 20:30 lib64 -> usr/lib64
dr-xr-xr-x 199 65534 65534    0 Mar 15 20:52 proc
drwxr-xr-x   1     0     0    0 Mar 15 20:51 tmp
drwxr-xr-x   1     0     0   68 Mar 15 20:30 usr

[/]$ ls -la /System
total 12
drwxr-xr-x 1 0 0  160 Mar 15 20:50 .
drwxr-xr-x 1 0 0  136 Mar 15 20:52 ..
-rw-r--r-- 1 0 0  280 Mar 15 20:46 Build.env
drwxr-xr-x 1 0 0   18 Mar 15 20:48 Camera
drwxr-xr-x 1 0 0 7448 Mar 15 20:50 Libraries
drwxr-xr-x 1 0 0  156 Mar 15 20:46 Security
-rw-r--r-- 1 0 0  169 Mar 15 20:30 Sysroot.cmake
drwxr-xr-x 1 0 0 1500 Mar 15 20:50 bin
drwxr-xr-x 1 0 0  132 Mar 15 20:30 etc
drwxr-xr-x 1 0 0 1966 Mar 15 20:50 include
lrwxrwxrwx 1 0 0    9 Mar 15 20:30 lib -> Libraries
drwxr-xr-x 1 0 0  140 Mar 15 20:30 libexec
drwxr-xr-x 1 0 0   90 Mar 15 20:50 sbin
drwxr-xr-x 1 0 0  112 Mar 15 20:50 share
drwxr-xr-x 1 0 0   12 Mar 15 20:47 var
```

## Copying
Anyone can use this public domain work without having to seek authorisation, no one can ever own it.
