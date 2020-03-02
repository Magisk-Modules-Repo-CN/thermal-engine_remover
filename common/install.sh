make_empty_conf() {
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
  ui_print " "
  ui_print " - 选择方法 -"
  ui_print "   选择您想要使用的替换方法:"
  ui_print "   [音量+] = conf(推荐)"
  ui_print "   [音量-] = binary(如果conf模式不生效，请尝试这个)"
  ui_print " "
  ui_print "- 正在进行替换"
  if $VKSEL; then
    make_empty_conf
  else
    make_empty_bin	
  fi