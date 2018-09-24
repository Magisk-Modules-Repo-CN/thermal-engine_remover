##########################################################################################
#
# Magisk 模块配置脚本示例
# by topjohnwu
# 翻译: cjybyjk
#
##########################################################################################
##########################################################################################
#
# 说明:
#
# 1. 将您的文件放入 system 文件夹 (删除 placeholder 文件)
# 2. 将模块信息写入 module.prop
# 3. 在这个文件中进行设置 (config.sh)
# 4. 如果您需要在启动时执行命令, 请把它们加入 common/post-fs-data.sh 或 common/service.sh
# 5. 如果需要修改系统属性(build.prop), 请把它加入 common/system.prop
#
##########################################################################################

##########################################################################################
# 配置
##########################################################################################

# 如果您需要启用 Magic Mount, 请把它设置为 true
# 大多数模块都需要启用它
AUTOMOUNT=true

# 如果您需要加载 system.prop, 请把它设置为 true
PROPFILE=false

# 如果您需要执行 post-fs-data 脚本, 请把它设置为 true
POSTFSDATA=false

# 如果您需要执行 service 脚本, 请把它设置为 true
LATESTARTSERVICE=false

##########################################################################################
# 安装信息
##########################################################################################

# 在这里设置您想要在模块安装过程中显示的信息

print_modname() {
  ui_print "*******************************"
  ui_print "    thermal-engine Remover     "
  ui_print "*******************************"
}

##########################################################################################
# 替换列表
##########################################################################################

# 列出您想在系统中直接替换的所有目录
# 查看文档，了解更多关于Magic Mount如何工作的信息，以及您为什么需要它

# 这是个示例
REPLACE="
/system/app/Youtube
/system/priv-app/SystemUI
/system/priv-app/Settings
/system/framework
"

# 在这里构建您自己的列表，它将覆盖上面的示例
# 如果你不需要替换任何东西，!千万不要! 删除它，让它保持现在的状态
REPLACE="
"

##########################################################################################
# 权限设置
##########################################################################################

set_permissions() {
  # 只有一些特殊文件需要特定的权限
  # 默认的权限应该适用于大多数情况

  # 下面是 set_perm 函数的一些示例:

  # set_perm_recursive  <目录>                <所有者> <用户组> <目录权限> <文件权限> <上下文> (默认值是: u:object_r:system_file:s0)
  # set_perm_recursive  $MODPATH/system/lib       0       0       0755        0644

  # set_perm  <文件名>                         <所有者> <用户组> <文件权限> <上下文> (默认值是: u:object_r:system_file:s0)
  # set_perm  $MODPATH/system/bin/app_process32   0       2000      0755       u:object_r:zygote_exec:s0
  # set_perm  $MODPATH/system/bin/dex2oat         0       2000      0755       u:object_r:dex2oat_exec:s0
  # set_perm  $MODPATH/system/lib/libart.so       0       0         0644

  # 以下是默认权限，请勿删除
  set_perm_recursive  $MODPATH  0  0  0755  0644

  set_perm  $MODPATH/system/bin/thermal-engine 0 0 0755
  set_perm  $MODPATH/vendor/bin/thermal-engine 0 0 0755
}

##########################################################################################
# 自定义函数
##########################################################################################

# 这个文件 (config.sh) 将被安装脚本在 util_functions.sh 之后 source 化(设置为环境变量)
# 如果你需要自定义操作, 请在这里以函数方式定义它们, 然后在 update-binary 里调用这些函数
# 不要直接向 update-binary 添加代码，因为这会让您很难将模块迁移到新的模板版本
# 尽量不要对 update-binary 文件做其他修改，尽量只在其中执行函数调用

make_empty_conf()
  mkdir -p ${MODPATH}/system/etc
  mkdir -p ${MODPATH}/system/vendor/etc
  for tconf in $(ls /system/etc/thermal-engine*.conf /system/vendor/etc/thermal-engine*.conf)
  do
    ui_print "  conf: 替换了${tconf}"
    touch ${MODPATH}${tconf}
  done
}

make_empty_bin() {
  mkdir -p ${MODPATH}/system/bin
  mkdir -p ${MODPATH}/system/vendor/bin
  mkdir ${MODPATH}/system/vendor/lib
  mkdir ${MODPATH}/system/vendor/lib64
  touch $MODPATH/system/bin/thermal-engine
  touch $MODPATH/system/vendor/bin/thermal-engine
  touch $MODPATH/system/vendor/lib/libthermalioctl.so
  touch $MODPATH/system/vendor/lib/libthermalclient.so
  touch $MODPATH/system/vendor/lib64/libthermalioctl.so
  touch $MODPATH/system/vendor/lib64/libthermalclient.so
}

# Keycheck binary by someone755 @Github, idea for code below by Zappo @xda-developers
KEYCHECK=$INSTALLER/common/keycheck
chmod 755 $KEYCHECK
 keytest() {
  ui_print " - 音量键测试 -"
  ui_print "   按下 [音量+] 键:"
  (/system/bin/getevent -lc 1 2>&1 | /system/bin/grep VOLUME | /system/bin/grep " DOWN" > $INSTALLER/events) || return 1
  return 0
}

chooseport() {	
  #note from chainfire @xda-developers: getevent behaves weird when piped, and busybox grep likes that even less than toolbox/toybox grep
  while (true); do
    /system/bin/getevent -lc 1 2>&1 | /system/bin/grep VOLUME | /system/bin/grep " DOWN" > $INSTALLER/events
    if (`cat $INSTALLER/events 2>/dev/null | /system/bin/grep VOLUME >/dev/null`); then
      break
    fi
  done
  if (`cat $INSTALLER/events 2>/dev/null | /system/bin/grep VOLUMEUP >/dev/null`); then
    return 0
  else
    return 1
  fi	
}

chooseportold() {
  # Calling it first time detects previous input. Calling it second time will do what we want
  $KEYCHECK
  $KEYCHECK
  SEL=$?
  if [ "$1" == "UP" ]; then
    UP=$SEL
  elif [ "$1" == "DOWN" ]; then
    DOWN=$SEL
  elif [ $SEL -eq $UP ]; then
    return 0
  elif [ $SEL -eq $DOWN ]; then
    return 1
  else
    abort "   未检测到音量键!"
  fi
}

go_replace() {
  if keytest; then
    FUNCTION=chooseport
  else
    FUNCTION=chooseportold
    ui_print "   ! 检测到遗留设备! 使用旧的 keycheck 方案"
    ui_print " "
    ui_print "- 进行音量键编程 -"
    ui_print "   再次按下[音量+]键:"
    $FUNCTION "UP"
    ui_print "   按下[音量-]键"
    $FUNCTION "DOWN"
  fi
  ui_print " "
  ui_print " - 选择方法 -"
  ui_print "   选择您想要使用的替换方法:"
  ui_print "   [音量+] = conf(推荐)"
  ui_print "   [音量-] = binary(如果conf模式不生效，请尝试这个)"
  ui_print " "
  ui_print "- 正在进行替换"
  if $FUNCTION; then
    make_empty_conf
  else
    make_empty_bin	
  fi
}
