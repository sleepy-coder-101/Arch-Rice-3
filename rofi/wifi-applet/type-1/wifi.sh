#!/usr/bin/env bash

## Author : Aditya Shakya (adi1090x)
## Github : @adi1090x
#
## Rofi   : Launcher (Modi Drun, Run, File Browser, Window)
#
## Available Styles
#
## style-1     style-2     style-3     style-4     style-5
## style-6     style-7     style-8     style-9     style-10
## style-11    style-12    style-13    style-14    style-15

dir="$HOME/.config/rofi/wifi-applet/type-1"
theme='style-6'

## Run
#rofi \
#    -show drun \
#    -theme ${dir}/${theme}.rasi


# Starts a scan of available broadcasting SSIDs
nmcli dev wifi rescan

FIELDS=SSID,SECURITY,BARS
POSITION=0
YOFF=0
XOFF=0


LIST=$(nmcli --fields "$FIELDS" device wifi list | sed '/^--/d' | awk '!seen[$1,$2]++')
# For some reason rofi always approximates character width 2 short... hmmm
RWIDTH=$(($(echo "$LIST" | head -n 1 | awk '{print length($0); }')+2))
# Dynamically change the height of the rofi menu
LINENUM=$(echo "$LIST" | wc -l)
# Gives a list of known connections so we can parse it later
KNOWNCON=$(nmcli connection show)
# Really janky way of telling if there is currently a connection
CONSTATE=$(nmcli -fields WIFI g)

CURRSSID=$(LANGUAGE=C nmcli -t -f active,ssid dev wifi | awk -F: '$1 ~ /^yes/ {print $2}')

if [[ ! -z $CURRSSID ]]; then
	HIGHLINE=$(echo  "$(echo "$LIST" | awk -F "[  ]{2,}" '{print $1}' | grep -Fxn -m 1 "$CURRSSID" | awk -F ":" '{print $1}') + 1" | bc )
fi

# HOPEFULLY you won't need this as often as I do
# If there are more than 8 SSIDs, the menu will still only have 8 lines
if [ "$LINENUM" -gt 8 ] && [[ "$CONSTATE" =~ "enabled" ]]; then
	LINENUM=8
elif [[ "$CONSTATE" =~ "disabled" ]]; then
	LINENUM=1
fi


if [[ "$CONSTATE" =~ "enabled" ]]; then
	TOGGLE="Toggle Off"
elif [[ "$CONSTATE" =~ "disabled" ]]; then
	TOGGLE="Toggle On"
fi



CHENTRY=$(echo -e "$TOGGLE\nManual\n$LIST" | uniq -u | rofi -dmenu -p "Wi-Fi SSID: " -lines "$LINENUM" -a "$HIGHLINE" -location "$POSITION" -yoffset "$YOFF" -xoffset "$XOFF" -width -"$RWIDTH" -theme ${dir}/${theme}.rasi )
#echo "$CHENTRY"
CHSSID=$(echo "$CHENTRY" | sed  's/\s\{2,\}/\|/g' | awk -F "|" '{print $1}')
#echo "$CHSSID"

# If the user inputs "Manual" as their SSID in the start window, it will bring them to this screen
if [ "$CHENTRY" = "Manual" ] ; then
	# Manual entry of the SSID and password (if appplicable)
	MSSID=$(echo "enter the SSID of the network (SSID,password)" | rofi -dmenu -p "Manual Entry: " -lines 1 -theme ${dir}/${theme}.rasi
 )
	# Separating the password from the entered string
	MPASS=$(echo "$MSSID" | awk -F "," '{print $2}')

	#echo "$MSSID"
	#echo "$MPASS"

	# If the user entered a Manual password, then use the password nmcli command
	if [ "$MPASS" = "" ]; then
		nmcli dev wifi con "$MSSID"
	else
		nmcli dev wifi con "$MSSID" password "$MPASS"
	fi

elif [ "$CHENTRY" = "Toggle On" ]; then
	nmcli radio wifi on

elif [ "$CHENTRY" = "Toggle Off" ]; then
	nmcli radio wifi off

else

	# If the connection is already in use, then this will still be able to get the SSID
	if [ "$CHSSID" = "*" ]; then
		CHSSID=$(echo "$CHENTRY" | sed  's/\s\{2,\}/\|/g' | awk -F "|" '{print $3}')
	fi

	# Parses the list of preconfigured connections to see if it already contains the chosen SSID. This speeds up the connection process
	if [[ $(echo "$KNOWNCON" | grep "$CHSSID") = "$CHSSID" ]]; then
		nmcli con up "$CHSSID"
	else
		if [[ "$CHENTRY" =~ "WPA2" ]] || [[ "$CHENTRY" =~ "WEP" ]]; then
			WIFIPASS=$(echo "if connection is stored, hit enter" | rofi -dmenu -p "password: " -lines 1 -theme ${dir}/${theme}.rasi
 )
		fi
		nmcli dev wifi con "$CHSSID" password "$WIFIPASS"
	fi

fi




