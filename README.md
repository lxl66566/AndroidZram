# AndroidZram

为 Android 手机提供 zram 内存优化。zram 是 linux 上的一种内存压缩技术，可以减少内存占用。

fork 自 [HChenX/MemoryOpt](https://github.com/HChenX/MemoryOpt)，移除 AppRetention 模块并优先使用 zstd 压缩算法。

模块原作者：`焕晨HChen`。

## 使用方法

在 Release 中下载 zip，在 Magisk 中安装即可。
