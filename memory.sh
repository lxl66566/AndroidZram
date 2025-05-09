# Author: 焕晨HChen
MODDIR=${0%/*}
mSwapConfig="$MODDIR/swap.ini"

main() {
    {
        echo "###############################################"
        time=$(date "+%Y年%m月%d日_%H时%M分%S秒")
        echo "手机品牌: $(getprop ro.product.brand)"
        echo "手机型号: $(getprop ro.product.device)"
        echo "上市名称: $(getprop ro.product.marketname)"
        echo "安卓版本: $(getprop ro.build.version.release)"
        echo "内存大小: $(expr $(expr $(grep 'MemTotal' </proc/meminfo | tr -cd "0-9") / 1048576) + 1)"
        echo "内核版本: $(uname -r)"
        if [[ -n $(getprop ro.miui.ui.version.name) ]]; then
            if [[ $(getprop ro.miui.ui.version.name) == "V816" ]]; then
                echo "Hyper 版本: $(getprop ro.product.build.version.incremental)"
            else
                echo "MIUI 版本: MIUI $(getprop ro.miui.ui.version.name) - $(getprop ro.build.version.incremental)"
            fi
        else
            echo "系统版本: $(getprop ro.product.build.version.incremental)"
        fi
        echo "开机时间: $time"
        echo "###############################################"
        echo ""
        # 检查并导入文件
        if [[ -f $mSwapConfig ]]; then
            if . "$mSwapConfig"; then
                echo "- [i]: 配置文件读取成功！"
            else
                echo "- [!]: 配置文件读取异常！" && exit 1
            fi
        else
            echo "- [!]: 缺少 $mSwapConfig 文件！" && exit 1
        fi
        initZram
        initVm
    } >>"$MODDIR"/log.txt
}

# 输出日志
printLog() {
    result=$(cat "$2" | head -n 1)
    if [[ $1 == "$result" ]]; then
        echo "- [i]: 写入: $2, 目标值: $1, 实际值: $result"
    else
        echo "- [!]: 写入: $2, 目标值: $1, 实际值: $result"
    fi
}

# 设置参数
setValue() {
    if [[ -f $2 ]]; then
        chmod 666 "$2" &>/dev/null
        if echo "$1" >"$2"; then
            chmod 664 "$2" &>/dev/null
            printLog "$1" "$2"
        else
            echo "- [!]: 无法写入 $2 文件！"
        fi
    else
        echo "- [!]: $2 文件不存在！"
    fi
}

initZram() {
    # 检查是否支持
    if [[ ! -e /dev/block/zram0 && ! -e /sys/class/zram-control ]]; then
        echo "- [!]: 内核不支持 ZRAM！"
        exit 1
    fi
    echo "- [i]: 内核支持 ZRAM！"
    
    backing_dev=$(cat /sys/block/zram0/backing_dev)
    echo "- [i]: 获取正在使用的回写块地址: $backing_dev"
    echo "- [i]: 重置 ZRAM！"
    for z in /dev/block/zram*; do
        swapoff "$z" &>/dev/null
    done
    setValue 1 /sys/block/zram0/reset
    
    if [[ $backing_dev != "" && $backing_dev != "none" ]]; then
        echo "- [i]: 恢复回写块地址！"
        setValue "$backing_dev" /sys/block/zram0/backing_dev
    fi
    setValue 0 /sys/block/zram0/writeback_limit_enable
    
    echo "- [i]: 设置压缩模式: $algorithm"
    setValue $algorithm /sys/class/block/zram0/comp_algorithm
    
    echo "- [i]: 设置 ZRAM 大小！"
    zramSize=$(expr $(expr $(grep 'MemTotal' </proc/meminfo | tr -cd "0-9") / 1048576) + 2)
    setValue "$zramSize"G /sys/block/zram0/disksize
    
    echo "- [i]: 初始化 ZRAM！"
    mkswap /dev/block/zram0 &>/dev/null
    
    echo "- [i]: 启动 ZRAM！"
    swapon /dev/block/zram0 &>/dev/null
}

initVm() {
    # 设置 vm 参数
    echo "- [i]: 设置 vm 参数优化！"
    
    echo "130" >"/proc/sys/vm/swappiness"
    if [[ $? -eq 1 ]]; then swappiness=80; else swappiness=130; fi
    setValue $swappiness /proc/sys/vm/swappiness
    
    setValue 5 /proc/sys/vm/dirty_background_ratio      # k80p 10
    setValue 10 /proc/sys/vm/dirty_ratio                # k80p 20
    setValue 1000 /proc/sys/vm/dirty_expire_centisecs   # k80p 3000
    setValue 100 /proc/sys/vm/dirty_writeback_centisecs # k80p 500
    setValue 125 /proc/sys/vm/vfs_cache_pressure        # k80p 100
    
    # 杀死触发oom的那个进程, k80p 0
    setValue 0 /proc/sys/vm/oom_kill_allocating_task
    # 是否打印 oom日志, k80p 1
    setValue 0 /proc/sys/vm/oom_dump_tasks
    # 是否要允许压缩匿名页
    setValue 1 /proc/sys/vm/compact_unevictable_allowed
    # io调试开关
    setValue 0 /proc/sys/vm/block_dump
    # vm 状态更新频率, k80p 1
    setValue 3 /proc/sys/vm/stat_interval
    # 是否允许过量使用运存
    setValue 1 /proc/sys/vm/overcommit_memory
    # 触发oom后怎么抛异常
    setValue 0 /proc/sys/vm/panic_on_oom
    # 此参数决定了内核在后台应该压缩内存的力度。参数取 [0, 100] 范围内的值, k80p 0
    setValue 25 /proc/sys/vm/compaction_proactiveness
    
    if [[ $algorithm == "zstd" ]]; then
        setValue 0 /proc/sys/vm/page-cluster
    else
        # k80p 3
        setValue 1 /proc/sys/vm/page-cluster
    fi
}

main
