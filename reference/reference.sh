#!/bin/bash

curl "http://192.168.2.8/api/4e5e32430d07d42371523af396f0b9f/" > get_4e5e32430d07d42371523af396f0b9f.json
curl --request PUT -d '{"bri":0,"on":true,"sat":255}' "http://192.168.2.8/api/4e5e32430d07d42371523af396f0b9f/lights/1/state" > put_4e5e32430d07d42371523af396f0b9f_lights_1_state.json
curl --request PUT -d '{"name":"TV-Left-Upper"}' "http://192.168.2.8/api/4e5e32430d07d42371523af396f0b9f/lights/1" > put_4e5e32430d07d42371523af396f0b9f_lights_1.json
curl --tcp-nodelay --request PUT -d '{"on":true,"bri":254,"hue":51000,"sat":254}' "http://192.168.2.8/api/4e5e32430d07d42371523af396f0b9f/groups/6/action" > put_4e5e32430d07d42371523af396f0b9f_groups_6_action.json
curl "http://192.168.2.8/api/4e5e32430d07d42371523af396f0b9f/lights" > get_4e5e32430d07d42371523af396f0b9f_lights.json
curl "http://192.168.2.8/api/4e5e32430d07d42371523af396f0b9f/groups" > get_4e5e32430d07d42371523af396f0b9f_groups.json
curl "https://www.meethue.com/api/nupnp" > get_nupnp.json
