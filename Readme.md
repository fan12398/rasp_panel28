# 使用说明

1.将屏幕插到树莓派上, 并用铜柱和螺丝固定  
2.上电，并运行install_all.sh, 如果不需要使用触屏，运行install_disp_only.sh即可  
3.安装完在之后，树莓派会自动重启

在`/boot/config.txt`里添加以下内容，
```
hdmi_force_hotplug=1
hdmi_group=2
hdmi_mode=87
hdmi_cvt=320 240 60 1 0 0 0
```
`hdmi_cvt=<width> <height> <framerate> <aspect> <margins> <interlace> <rb>`  

Value|Default|Description
--|--|:--
width|(required)|width in pixels
height|(required)|height in pixels
framerate|(required)|framerate in Hz
aspect|3|aspect ratio 1=4:3, 2=14:9, 3=16:9, 4=5:4, 5=16:10, 6=15:9
margins|0|0=margins disabled, 1=margins enabled
interlace|0|0=progressive, 1=interlaced
rb|0|0=normal, 1=reduced blanking  

`/boot/config.txt`参数的详细解释见以下链接：
https://www.raspberrypi.org/documentation/configuration/config-txt/README.md

