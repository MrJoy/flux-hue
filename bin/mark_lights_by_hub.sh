#!/bin/bash
# TODO: Use a sequence of sat/brightness values to indicate ordering of lights.
HUE_BRIDGE_IP=192.168.2.10 bin/hue groups set 0 --state=on --bri=255 --sat=255 --hue=0
HUE_BRIDGE_IP=192.168.2.6 bin/hue groups set 0 --state=on --bri=255 --sat=255 --hue=25000
HUE_BRIDGE_IP=192.168.2.7 bin/hue groups set 0 --state=on --bri=255 --sat=255 --hue=45000
HUE_BRIDGE_IP=192.168.2.9 bin/hue groups set 0 --state=on --bri=255 --sat=255 --hue=17500
