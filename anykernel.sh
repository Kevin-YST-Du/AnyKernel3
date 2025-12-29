### AnyKernel3 Ramdisk Mod Script
## KernelSU with SUSFS By Numbersf
## osm0sis @ xda-developers

### AnyKernel setup
# global properties
properties() { '
kernel.string=KernelSU by KernelSU Developers
do.devicecheck=0
do.modules=0
do.systemless=0
do.cleanup=1
do.cleanuponabort=1
device.name1=
device.name2=
device.name3=
device.name4=
device.name5=
supported.versions=
supported.patchlevels=
supported.vendorpatchlevels=
'; } # end properties

### AnyKernel install
## boot shell variables
block=boot
is_slot_device=auto
ramdisk_compression=auto
patch_vbmeta_flag=auto
no_magisk_check=1

# import functions/variables and setup patching - see for reference (DO NOT REMOVE)
. tools/ak3-core.sh

kernel_version=$(cat /proc/version | awk -F '-' '{print $1}' | awk '{print $3}')
case $kernel_version in
    4.1*) ksu_supported=true ;;
    5.1*) ksu_supported=true ;;
    6.1*) ksu_supported=true ;;
    6.6*) ksu_supported=true ;;
    *) ksu_supported=false ;;
esac

ui_print "  -> ksu_supported: $ksu_supported"
$ksu_supported || abort "  -> Non-GKI device, abort."

# 确定 root 方式 (Magisk 检测)
if [ -d /data/adb/magisk ] || [ -f /sbin/.magisk ]; then
    ui_print "检测到 Magisk，当前 Root 方式为 Magisk。在此情况下刷写 KSU 内核有很大可能会导致你的设备变砖，是否要继续？"
    ui_print "Magisk detected, current root method is Magisk. Flashing the KSU kernel in this case may brick your device, do you want to continue?"
    ui_print "请选择操作："
    ui_print "Please select an action:"
    ui_print "音量上键：退出脚本 (No)"
    ui_print "音量下键：继续安装 (Yes)"
    key_click=""
    while [ "$key_click" = "" ]; do
        key_click=$(getevent -qlc 1 | awk '{ print $3 }' | grep 'KEY_VOLUME')
        sleep 0.2
    done
    case "$key_click" in
        "KEY_VOLUMEUP") 
            ui_print "您选择了退出脚本"
            ui_print "Exiting…"
            exit 0
            ;;
        "KEY_VOLUMEDOWN")
            ui_print "You have chosen to continue the installation"
            ;;
        *)
            ui_print "未知按键，退出脚本"
            ui_print "Unknown key, exit script"
            exit 1
            ;;
    esac
fi

# 检查内核镜像是否存在
if [ ! -f "$AKHOME/Image" ]; then
    ui_print " ❌ 错误：内核镜像文件 Image 未找到"
    abort "❌安装失败：没有内核镜像文件"
fi

ui_print " "
# =======================================================
# 📌 内核刷入
# =======================================================

ui_print "开始安装内核..."
ui_print "Power by GitHub@Numbersf(Aq1298&咿云冷雨)"
if [ -L "/dev/block/bootdevice/by-name/init_boot_a" ] || [ -L "/dev/block/by-name/init_boot_a" ]; then
    split_boot
    flash_boot
else
    dump_boot
    write_boot
fi

# =======================================================
# 📌 SUSFS 模块安装
# =======================================================

# 检查 SUSFS 模块是否存在
if [ -f "$AKHOME/ksu_module_susfs_1.5.2+_Release.zip" ] || [ -f "$AKHOME/ksu_module_susfs_1.5.2+_CI.zip" ]; then
    ui_print " "
    ui_print "安装 SUSFS 模块?"
    ui_print "Install susfs4ksu Module?"
    ui_print "音量上键：跳过安装 (NO)；音量下键：继续安装 (YES)"

    key_click=""
    while [ "$key_click" = "" ]; do
        key_click=$(getevent -qlc 1 | awk '{ print $3 }' | grep 'KEY_VOLUME')
        sleep 0.2
    done
    case "$key_click" in
        "KEY_VOLUMEDOWN")
            # 用户选择继续安装，提示选择模块版本
            ui_print "请选择要安装的 SUSFS 模块版本："
            ui_print "Please select the SUSFS module version to install:"
            ui_print "音量上键：Release 版本 (ksu_module_susfs_1.5.2+_Release.zip)"
            ui_print "音量下键：CI 版本 (ksu_module_susfs_1.5.2+_CI.zip)"

            MODULE_PATH=""
            key_click=""
            while [ "$key_click" = "" ]; do
                key_click=$(getevent -qlc 1 | awk '{ print $3 }' | grep 'KEY_VOLUME')
                sleep 0.2
            done
            case "$key_click" in
                "KEY_VOLUMEUP")
                    if [ -f "$AKHOME/ksu_module_susfs_1.5.2+_Release.zip" ]; then
                        MODULE_PATH="$AKHOME/ksu_module_susfs_1.5.2+_Release.zip"
                        ui_print "  -> Selected SUSFS Module: Release version"
                    else
                        ui_print "  -> Release version not found, skipping installation"
                        MODULE_PATH=""
                    fi
                    ;;
                "KEY_VOLUMEDOWN")
                    if [ -f "$AKHOME/ksu_module_susfs_1.5.2+_CI.zip" ]; then
                        MODULE_PATH="$AKHOME/ksu_module_susfs_1.5.2+_CI.zip"
                        ui_print "  -> Selected SUSFS Module: CI version"
                    else
                        ui_print "  -> CI version not found, skipping installation"
                        MODULE_PATH=""
                    fi
                    ;;
                *)
                    ui_print "  -> Unknown key input, skipping SUSFS module installation"
                    MODULE_PATH=""
                    ;;
            esac

            # 安装选定的 SUSFS 模块
            if [ -n "$MODULE_PATH" ]; then
                KSUD_PATH="/data/adb/ksud"
                if [ -f "$KSUD_PATH" ]; then
                    ui_print "Installing SUSFS Module..."
                    /data/adb/ksud module install "$MODULE_PATH"
                    ui_print "Installation Complete"
                else
                    ui_print "KSUD Not Found, Skipping Installation"
                fi
            fi
            ;;
        "KEY_VOLUMEUP")
            ui_print "Skipping SUSFS Module Installation"
            ;;
        *)
            ui_print "Unknown Key Input, Skipping Installation"
            ;;
    esac
else
    ui_print "  -> No SUSFS Module found, Skipping Installation"
fi

# =======================================================
# 📌 SukiSU Ultra APK 安装
# =======================================================

ui_print " "
ui_print "安装 SukiSU Ultra APK 作为用户应用？"
ui_print "Install SukiSU Ultra APK as user app?"
ui_print "音量上键：跳过安装 (NO)；音量下键：安装APK (YES)"
ui_print "安装时APK闪退是正常现象"
ui_print "It is normal for APK to crash during installation."

key_click=""
while [ "$key_click" = "" ]; do
    key_click=$(getevent -qlc 1 | awk '{ print $3 }' | grep 'KEY_VOLUME')
    sleep 0.2
done
case "$key_click" in
    "KEY_VOLUMEDOWN")
        apk_file=$(ls $AKHOME/*.apk 2>/dev/null | head -n1)
        ui_print "  -> 正在安装 SukiSU Ultra APK 到用户应用目录..."
        if [ -n "$apk_file" ]; then
            pm_install_output=$(pm install -r "$apk_file" 2>&1)
            if [ $? -eq 0 ]; then
                ui_print "  -> SukiSU Ultra APK 安装完成"
            else
                ui_print "  -> SukiSU Ultra APK 安装失败: $pm_install_output"
            fi
        else
            ui_print "  -> 未找到 SukiSU Ultra APK，尝试安装失败"
        fi
        ;;
    "KEY_VOLUMEUP")
        ui_print "  -> 跳过 SukiSU Ultra APK 安装"
        ;;
    *)
        ui_print "  -> 未知按键输入，跳过 SukiSU Ultra APK 安装"
        ;;
esac
