sudo mv /boot/backup_config.txt /boot/config.txt
sudo mv /etc/backup_rc.local /etc/rc.local
sudo rm /etc/modules-load.d/fbtft.conf
sudo rm /etc/modprobe.d/fbtft_option.conf
sudo rm /usr/share/X11/xorg.conf.d/99-fbdev.conf
sudo rm /usr/local/bin/fbcp
sudo rm /etc/X11/xorg.conf.d/99-calibration.conf

echo "Uninstalling complete."

echo "Now rebooting..."
sleep 1
sudo reboot
