# Author: 焕晨HChen

main() {
    print "--------------------------------------------"
    
    initConfig
    initPermissions
    
    printLog "- [i]: 原作者: 焕晨HChen"
    printLog "- [i]: 修改者: lxl66566"
    printLog "- [i]: 安装完成！"
}

# 设置压缩模式
initConfig() {
    compAlgorithm=$(getConfigValue algorithm)
    persist=$(getConfigValue persist)
    
    printLog "- [i]: 正在检测可用压缩模式！"
    if [[ $persist == "true" ]]; then
        algorithm=$compAlgorithm
        sed -i '6d' "$MODPATH/swap.ini"
        sed -i '5a '"persist=true"'' "$MODPATH/swap.ini"
    else
        result=$(cat /sys/block/zram0/comp_algorithm)
        zramModes=$(echo "$result" | sed 's/\[//g' | sed 's/]//g' | sed 's/ /\n/g')
        # 优先选择 zstd，如果不可用则选择其他模式
        if echo "$zramModes" | grep -q zstd; then
            algorithm=zstd
            elif echo "$zramModes" | grep -q lz4; then
            algorithm=lz4
            elif echo "$zramModes" | grep -q lzo-rle; then
            algorithm=lzo-rle
        else
            algorithm=lzo
        fi
    fi
    if [[ -z $algorithm ]]; then
        printLog "- [!]: 获取 zram 压缩模式失败！"
        exit 1
    else
        sed -i '2a '"algorithm=$algorithm"'' "$MODPATH/swap.ini"
        printLog "- [i]: 设置 zram 压缩算法为: $algorithm"
    fi
    
    # Changed: 放弃修改！！
    #    printLog "- [i]: 正在检查手机品牌！"
    #    printLog "- [i]: 你的手机品牌是: $(getprop ro.product.brand)"
    #    if [[ $(getprop ro.product.brand) == "samsung" ]]; then
    #        echo -n "
    #persist.sys.minfree_12g=1,1,1,1,1,1
    #persist.sys.minfree_6g=1,1,1,1,1,1
    #persist.sys.minfree_8g=1,1,1,1,1,1
    #persist.sys.minfree_def=1,1,1,1,1,1
    #ro.slmk.2nd.dha_cached_max=2147483647
    #ro.slmk.dha_cached_max=2147483647
    #ro.slmk.dha_empty_max=2147483647
    #ro.slmk.2nd.dha_lmk_scale=-1
    #ro.slmk.dha_lmk_scale=-1
    #ro.slmk.dha_lmk_scale=-1
    #ro.slmk.2nd.swap_free_low_percentage=0
    #ro.slmk.swap_free_low_percentage=0
    #ro.slmk.cam_dha_ver=0
    #ro.slmk.chimera_quota_enable=false
    #ro.slmk.dha_2ndprop_thMB=1
    #ro.slmk.enable_upgrade_criad=false
    #ro.slmk.genai_reclaim_mode=false
    #ro.sys.kernelmemory.gmr.enabled=false
    #ro.sys.kernelmemory.umr.enabled=false
    #ro.sys.kernelmemory.umr.mem_free_low_threshold_kb=1
    #ro.sys.kernelmemory.umr.proactive_reclaim_battery_threshold=0
    #ro.sys.kernelmemory.umr.reclaimer.damon.enabled=false
    #ro.sys.kernelmemory.umr.reclaimer.onTrim.enabled=false" >>"$MODPATH"/system.prop
    #        printLog "- [i]:已为三星添加专属PROP修改！"
    #    fi
}

initPermissions() {
    set_perm_recursive "$MODPATH" 0 0 0777 0777
}

printLog() {
    echo "$@"
    sleep "$(echo "scale=3; $RANDOM/32768*0.2" | bc -l)"
}

findPath() {
    if [[ -d /data/adb/modules/ ]]; then
        find /data/adb/modules/ -maxdepth 1 -name "$1"
        elif [[ -d /data/adb/ksu/modules/ ]]; then
        find /data/adb/ksu/modules/ -maxdepth 1 -name "$1"
    fi
}

getConfigValue() {
    if [[ -f "/data/adb/modules/AndroidZram/swap.ini" ]]; then
        grep -v '^#' <"/data/adb/modules/AndroidZram/swap.ini" | grep "^$1=" | cut -f2 -d '='
    fi
}

main
