#Disable WACOM pointer when open the terminal
if [[ "$(echo lsusb | grep Wacom | head -n 1 2> /dev/null)" != "" ]]; then
xsetwacom --set "Wacom Intuos5 touch M Finger touch" Touch off
fi;
