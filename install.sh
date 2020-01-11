print_help()
{
echo "Usage: ./install.sh [0/90/180/270] [only_disp]"
echo "0: rotate 0 degrees"
echo "90: rotate 90 degrees"
echo "180: rotate 180 degrees"
echo "270: rotate 270 degrees"
echo "only_disp: do not install touch driver"
echo "default(no param): rotate 270 degrees and install touch driver"
}

function test_network()
{
    local timeout=1
    local target=www.qq.com
    local ret_code=`curl -I -s --connect-timeout ${timeout} ${target} -w %{http_code} | tail -n1`
    if [ "x$ret_code" = "x200" ]; then
        return 1
    else
        return 0
    fi
    return 0
}

rotation=270
install_touch=1
invalid=0
if [ $# -eq 0 ]; then
  echo "Use default parameters."
elif [ $# -eq 1 ]; then
  if [ $1 = only_disp ]; then
    install_touch=0
  elif [ $1 -eq 0 ] || [ $1 -eq 90 ] || [ $1 -eq 180 ] || [ $1 -eq 270 ]; then
    rotation=$1
  else
    invalid=1
  fi
elif [ $# -eq 2 ]; then
  if [ $1 = only_disp ]; then
    install_touch=0
	if [ $2 -eq 0 ] || [ $2 -eq 90 ] || [ $2 -eq 180 ] || [ $2 -eq 270 ]; then
      rotation=$2
    else
	  invalid=1
    fi
  elif [ $2 = only_disp ]; then
    install_touch=0
    if [ $1 -eq 0 ] || [ $1 -eq 90 ] || [ $1 -eq 180 ] || [ $1 -eq 270 ]; then
      rotation=$1
    else
      invalid=1
    fi
  else
    invalid=1
  fi
else
  invalid=1
fi

if [ $invalid -eq 1 ]; then
  echo "Invalid parameters input."
  print_help
  exit
fi
echo "Rotate $rotation degree."
if [ $install_touch -eq 1 ]; then
  echo "Enable installing touch driver."
else
  echo "Touch driver is ignored."
fi

#backup file /boot/config.txt
if [ ! -f /boot/backup_config.txt ]; then
  echo "Backup /boot/config.txt to /boot/backup_config.txt"
  sudo cp -rf /boot/config.txt /boot/backup_config.txt
fi
cp /boot/config.txt ./config.txt

echo "Installing display driver..."

#add spi=on to config.txt
match=`sed -n "/^.*dtparam=spi/=" config.txt`
mlines=($match)
if [ ${#mlines[@]} -eq 0 ]; then
  echo -e "\ndtparam=spi=on" >> config.txt
else
  sed -i "${mlines[0]}cdtparam=spi=on" config.txt
  for ((i=${#mlines[@]}-1;i>0;i--))
  do
    sed -i "${mlines[i]}d" config.txt
  done
fi

sudo cp -rf ./conf/fbtft.conf /etc/modules-load.d/fbtft.conf
fbtft_option="./conf/fbtft_option_$rotation.conf"
sudo cp -rf $fbtft_option /etc/modprobe.d/fbtft_option.conf
sudo cp -rf ./conf/99-fbdev.conf /usr/share/X11/xorg.conf.d/99-fbdev.conf

match=`sed -n "/^#HDMI settings added by rasp_panel28/=" config.txt`
mlines=($match)
if [ ${#mlines[@]} -ne 0 ]; then
  sed -i "${mlines[0]}d" config.txt
  sed -i "${mlines[0]}d" config.txt
  sed -i "${mlines[0]}d" config.txt
  sed -i "${mlines[0]}d" config.txt
  sed -i "${mlines[0]}d" config.txt
fi

read pi_model < /proc/device-tree/model
pi_model=${pi_model#*Pi }
if [ ${pi_model:0:1} != 4 ]; then
  echo "This board is not raspberry pi 4, so install fbcp."
  sudo install fbcp /usr/local/bin/fbcp
  if [ ! -f /etc/backup_rc.local ]; then
    echo "Backup /etc/rc.local to /etc/backup_rc.local"
    sudo cp -rf /etc/rc.local /etc/backup_rc.local
  fi
  cp /etc/rc.local ./rc
  match=`sed -n "/^fbcp/=" rc`
  mlines=($match)
  if [ ${#mlines[@]} -eq 0 ]; then
    sed -i "/^exit 0/ifbcp&" rc
  fi
  sudo cp -rf ./rc /etc/rc.local 
  rm ./rc
  
  #add hdmi settings
  hdmi_note="#HDMI settings added by rasp_panel28, comment the 4 lines below if you connect hdmi to your own monitor.\n"
  if [ $rotation -eq 0 ] || [ $rotation -eq 180 ]; then
    hdmi_setting="hdmi_force_hotplug=1\nhdmi_group=2\nhdmi_mode=87\nhdmi_cvt=240 320 60 1 0 0 0"
  else
    hdmi_setting="hdmi_force_hotplug=1\nhdmi_group=2\nhdmi_mode=87\nhdmi_cvt=320 240 60 1 0 0 0"
  fi
  echo -e "$hdmi_note$hdmi_setting" >> config.txt
fi

echo "Install display driver complete."

if [ $install_touch -eq 1 ]; then
  echo "Installing touch driver..."
  
  touch_setting="dtoverlay=ads7846,penirq=4,swapxy=1,pmax=255,xohms=80"
  match=`sed -n "/^.*dtoverlay=ads7846/=" config.txt`
  mlines=($match)
  if [ ${#mlines[@]} -eq 0 ]; then
    echo -e "\n$touch_setting" >> config.txt
  else
    sed -i "${mlines[0]}c$touch_setting" config.txt
    for ((i=${#mlines[@]}-1;i>0;i--))
    do
      sed -i "${mlines[i]}d" config.txt
    done
  fi
  
  echo "Installing xinput-calibrator and xserver-xorg-input-evdev..."
  if [ test_network ]; then
    sudo apt-get install -y xinput-calibrator xserver-xorg-input-evdev
  else
    echo "Network is not connected, please install xinput-calibrator and xserver-xorg-input-evdev manually or re-run this script."
  fi

  if [ -f /etc/X11/xorg.conf.d/40-libinput.conf ]; then
    sudo rm -rf /etc/X11/xorg.conf.d/40-libinput.conf
  fi
  if [ ! -d /etc/X11/xorg.conf.d ]; then
    sudo mkdir -p /etc/X11/xorg.conf.d
  fi
  
  sudo cp -rf /usr/share/X11/xorg.conf.d/10-evdev.conf /usr/share/X11/xorg.conf.d/45-evdev.conf
  calibration="./conf/calibration_$rotation.conf"
  sudo cp -rf $calibration /etc/X11/xorg.conf.d/99-calibration.conf
  echo "Install touch driver complete."
fi

sudo cp -rf ./config.txt /boot/config.txt
rm ./config.txt
chmod +x ./recalibrate.sh
chmod +x ./uninstall.sh

echo "Now rebooting..."
sleep 1
sudo reboot
