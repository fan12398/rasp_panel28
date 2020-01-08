print_help()
{
echo "Usage: ./install_disp_only.sh [0/90/180/270] [only_disp]"
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
if [ $# -eq 0 ]; then
  echo "Default rotate 270 degree, install display and touch drivers."
elif [ $# -eq 1 ] || [ $# -eq 2 ]; then
  if [ $1 -ne 0 ] && [ $1 -ne 90 ] && [ $1 -ne 180 ] && [ $1 -ne 270 ]; then
    echo "Invalid parameter."
    print_help
    exit
  else
    rotation=$1
    echo "Rotate "$rotation" degree."
  fi
  if [ $# -eq 2 ] && [ $2 = only_disp ]; then
      install_touch=0
	  echo "Touch driver is ignored."
  fi
else
  echo "Too many parameters."
  print_help
  exit
fi

#backup file /boot/config.txt
if [ ! -f /boot/backup_config.txt ]; then
  echo "Backup /boot/config.txt to /boot/backup_config.txt"
  sudo cp -rf /boot/config.txt /boot/backup_config.txt
fi
cp /boot/config.txt ./config.txt

# install display
echo "Installing display driver..."

#add spi=on to config.txt
match=`sed -n "/^.*dtparam=spi/=" config.txt`
mlines=($match)
if [ ${#mlines[@]} -eq 0 ]; then
  sudo echo -e "\ndtparam=spi=on" >> config.txt
else
  sudo sed -i "${mlines[0]}cdtparam=spi=on" config.txt
  for ((i=1;i<${#mlines[@]};i++))
  do
    sudo sed -i "${mlines[i]}d" config.txt
  done
fi


sudo cp -rf ./conf/fbtft.conf /etc/modules-load.d/fbtft.conf
fbtft_option="./conf/fbtft_option_"$rotation".conf"
sudo cp -rf $fbtft_option /etc/modprobe.d/fbtft_option.conf
sudo cp -rf ./conf/99-fbdev.conf /usr/share/X11/xorg.conf.d/99-fbdev.conf

read pi_model < /proc/device-tree/model
pi_model=${pi_model#*Pi }
if [ ${pi_model:0:1} != 4 ]; then
  echo "This board is not raspberry pi 4, so install fbcp."
  sudo install fbcp /usr/local/bin/fbcp
  
  #add hdmi settings
  hdmi_note="#HDMI settings added by rasp_panel28, comment the 4 lines below if you connect hdmi to your own monitor.\n"
  if [ $rotation -eq 0 ] || [ $rotation -eq 180 ]; then
    hdmi_setting="hdmi_force_hotplug=1\nhdmi_group=2\nhdmi_mode=87\nhdmi_cvt=240 320 60 1 0 0 0"
  else
    hdmi_setting="hdmi_force_hotplug=1\nhdmi_group=2\nhdmi_mode=87\nhdmi_cvt=320 240 60 1 0 0 0"
  fi
  
  match=`sed -n "/^#HDMI settings added by rasp_panel28/=" config.txt`
  if [ ${#match} -eq 0 ]; then
    echo "hdmi match empty"
    sudo echo -e "\n\n"$hdmi_note$hdmi_setting >> config.txt
  else
    sudo sed -i "$matchc$hdmi_note$hdmi_setting" config.txt
  fi
fi

echo "Install display driver complete."

if [ $install_touch -eq 1 ]; then
  echo "Installing touch driver..."
  
  #add dtoverlay=ads7846
  touch_setting="dtoverlay=ads7846,penirq=4,swapxy=1,pmax=255,xohms=80"
  match=`sed -n "/^.*dtoverlay=ads7846/=" config.txt`
  mlines=($match)
  if [ ${#mlines[@]} -eq 0 ]; then
    sudo echo -e "\n"$touch_setting >> config.txt
  else
    sudo sed -i "${mlines[0]}c$touch_setting" config.txt
    for ((i=1;i<${#mlines[@]};i++))
    do
      sudo sed -i "${mlines[i]}d" config.txt
    done
  fi
  
  echo "Installing xserver-xorg-input-evdev..."
  if [ test_network ]; then
    sudo apt-get install -y xserver-xorg-input-evdev
  else
    echo "Network is not connected, install local package"
  fi

  if [ -f /etc/X11/xorg.conf.d/40-libinput.conf ]; then
    sudo rm -rf /etc/X11/xorg.conf.d/40-libinput.conf
  fi
  if [ ! -d /etc/X11/xorg.conf.d ]; then
    sudo mkdir -p /etc/X11/xorg.conf.d
  fi

  calibration="./conf/calibration_"$rotation".conf"
  sudo cp -rf $calibration /etc/X11/xorg.conf.d/99-calibration.conf
  echo "Install touch driver complete."
fi

sudo cp -rf ./config.txt /boot/config.txt
rm ./config.txt

echo "Rebooting now..."
sleep 1
sudo reboot
