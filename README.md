# Flux Hue

Work with Philips Hue light bulbs from Ruby.

_Based on [hue](https://github.com/soffes/hue) by [Sam Soffes](https://github.com/soffes/hue)._

[![Code Climate](https://codeclimate.com/github/MrJoy/hue.png)](https://codeclimate.com/github/MrJoy/hue) [![Dependency Status](https://gemnasium.com/MrJoy/hue.png)](https://gemnasium.com/MrJoy/hue) <!--[![Gem Version](https://badge.fury.io/rb/hue.png)](http://badge.fury.io/rb/hue)-->

## Installation

Add this line to your application's `Gemfile`:

```ruby
gem 'flux-hue', github: 'MrJoy/flux-hue'
```

And then execute:

```bash
bundle
```

<!--
Or install it yourself as:

``` shell
$ gem install flux-hue
```
-->

## Usage

### First Usage

Press the button on your bridge, and within 30 seconds run `hue lights`.  This will create a user on the bridge for the app.

If you want to use your own user ID, use the `--user <your_preferred_id>` or set the environment variable `HUE_BRIDGE_USER`.  Be aware that the id *must* be 10..40 characters in length.


### Finding Bridges

The system is largely designed around the assumption that there is only one bridge, and normally it will be found either using SSDSP (UPnP) or failing that a proprietary mechanism that Philips provides but which requires Internet access.

For speed, or if you have multiple bridges, you may wish to identify what IP address your bridge(s) is/are on, so you can specify it explicitly on other commands.  This will be faster because no discovery needs to be performed, and gives explicit control of *which* bridge is in use, but if the bridge is assigned to a new IP address at some point, then requests will fail.

When you've discovered the IP(s) of your bridge(s) you can tell the `hue` command to use a particular IP via one of the following:

1. Set an environment variable named `HUE_BRIDGE_IP` with the bridge IP.
1. Pass a parameter to commands: `--ip <bridge IP>`.


### Commandline

#### Information About Bridges: `hue bridges`

Discover and show information about all bridges on the network.  The information is limited to that which can be found without a registered username on the bridge.

```bash
hue bridges
```

Example output:

```
INFO: Discovering bridges via SSDP...
+--------------+-----------+-------------+-------------------+-------------+------------------+
| ID           | Name      | IP          | MAC               | API Version | Software Version |
+--------------+-----------+-------------+-------------------+-------------+------------------+
| 0017881226f3 | Bridge-01 | 192.168.2.8 | 00:17:88:12:26:f3 | 1.7.0       | 01023599         |
+--------------+-----------+-------------+-------------------+-------------+------------------+
```

#### Information About Bridges: `hue bridge`

Discover and show information about a specific bridge on the network, with which you've registered a username.  This provides more detail than `hue bridges`.

```bash
hue bridge <id>
```

Example output:

```
INFO: Discovering bridges via SSDP...
+--------------+-----------+-------------+-------------------+---------+-------------+------------------+------------------------+-----------------+
| ID           | Name      | IP          | MAC               | Channel | API Version | Software Version | Update Info            | Button Pressed? |
+--------------+-----------+-------------+-------------------+---------+-------------+------------------+------------------------+-----------------+
| 0017881226f3 | Bridge-01 | 192.168.2.8 | 00:17:88:12:26:f3 | 25      | 1.7.0       | 01023599         | HUE0100 lamp 66013452  | false           |
+--------------+-----------+-------------+-------------------+---------+-------------+------------------+------------------------+-----------------+
```

#### Information About Groups: `hue groups`

Display groups the bridge knows about, along with their name and what lights are in each group.

This does not include information about whether the lights in a group are on/off/etc because groups themselves do not have state -- they're just a proxy for manipulating multiple lights in a single API request.

```bash
hue groups
```

Example output:

```
+----+----------+-----------+----------------------+
| ID | Name     | Light IDs | Lights               |
+----+----------+-----------+----------------------+
| 1  | TV       | 1         | TV-Left-Upper        |
|    |          | 2         | TV-Right-Upper       |
|    |          | 6         | TV-Left-Lower        |
|    |          | 14        | TV-Right-Lower       |
|    |          | 34        | TV-Center            |
| 2  | Kitchen  | 3         | Kitchen-02           |
|    |          | 4         | Kitchen-03           |
|    |          | 5         | Kitchen-01           |
|    |          | 16        | Kitchen-04           |
|    |          | 24        | Kitchen-05           |
|    |          | 25        | Kitchen-06           |
| 3  | Bed      | 11        | Bed-Right-Lower      |
|    |          | 12        | Bed-Left-Lower       |
|    |          | 17        | Bed-Left-Upper       |
|    |          | 20        | Bed-Right-Upper      |
|    |          | 21        | Bed-Center-Upper     |
|    |          | 35        | Bedroom-Right-Upper  |
|    |          | 36        | Bedroom-Right-Middle |
|    |          | 37        | Bedroom-Right-Lower  |
| 4  | Entryway | 9         | Entryway-Back        |
|    |          | 10        | Entryway-Middle      |
|    |          | 13        | Entryway-Front       |
| 5  | Lab      | 7         | Lab-Back-Right       |
|    |          | 8         | Lab-Back-Center      |
|    |          | 15        | Lab-Back-Left        |
|    |          | 18        | Lab-Middle-Left      |
|    |          | 19        | Lab-Front-Left       |
|    |          | 26        | Lab-Front-Right      |
|    |          | 27        | Lab-Middle-Right     |
|    |          | 28        | Lab-09               |
|    |          | 30        | Lab-06               |
| 6  | Library  | 22        | Library-Middle       |
|    |          | 23        | Library-Front        |
|    |          | 33        | Library-Back         |
+----+----------+-----------+----------------------+
```

#### Information About Lights: `hue lights`

Display lights the bridge knows about, along with a great deal of state information about each one.  The `--order` parameter takes a comma-separated list of column numbers, starting from 0.

```bash
hue lights
hue lights --order <columns>
```

Example output:

```
+----+----------------------+--------+----------------------+--------+------+-------+------------+------------+----------------+------+---------+--------+------------------+------------+
| ID | Type                 | Model  | Name                 | Status | Mode | Hue   | Saturation | Brightness | X/Y            | Temp | Alert   | Effect | Software Version | Reachable? |
+----+----------------------+--------+----------------------+--------+------+-------+------------+------------+----------------+------+---------+--------+------------------+------------+
| 1  | Extended color light | LCT002 | TV-Left-Upper        | On     | hs   | 38908 | 254        | 205        | 0.2592, 0.2222 | 153  | none    | none   | 66013452         | Yes        |
| 2  | Extended color light | LCT002 | TV-Right-Upper       | On     | xy   | 40907 | 253        | 247        | 0.2372, 0.1785 | 500  | none    | none   | 66013452         | Yes        |
| 3  | Dimmable light       | LWB004 | Kitchen-02           | Off    |      |       |            | 254        |                |      | none    |        | 66012040         | Yes        |
| 4  | Dimmable light       | LWB004 | Kitchen-03           | Off    |      |       |            | 254        |                |      | none    |        | 66012040         | Yes        |
| 5  | Dimmable light       | LWB004 | Kitchen-01           | Off    |      |       |            | 254        |                |      | none    |        | 66012040         | Yes        |
| 6  | Extended color light | LCT002 | TV-Left-Lower        | On     | xy   | 40834 | 253        | 236        | 0.2381, 0.1802 | 500  | none    | none   | 66013452         | Yes        |
| 7  | Extended color light | LCT002 | Lab-Back-Right       | On     | hs   | 35215 | 254        | 180        | 0.3008, 0.3042 | 153  | none    | none   | 66013452         | Yes        |
| 8  | Extended color light | LCT002 | Lab-Back-Center      | On     | xy   | 38360 | 253        | 208        | 0.2658, 0.2349 | 153  | none    | none   | 66013452         | Yes        |
| 9  | Color light          | LLC011 | Entryway-Back        | On     | xy   | 41059 | 106        | 165        | 0.3155, 0.3171 |      | none    | none   | 66013452         | Yes        |
| 10 | Color light          | LLC011 | Entryway-Middle      | On     | xy   | 42891 | 67         | 246        | 0.3584, 0.3379 |      | none    | none   | 66009461         | Yes        |
| 11 | Color light          | LST001 | Bed-Right-Lower      | On     | xy   | 40994 | 193        | 182        | 0.2175, 0.2461 |      | none    | none   | 66013452         | Yes        |
| 12 | Color light          | LST001 | Bed-Left-Lower       | On     | xy   | 40677 | 130        | 187        | 0.2890, 0.3026 |      | none    | none   | 66013452         | Yes        |
| 13 | Color light          | LST001 | Entryway-Front       | On     | xy   | 39894 | 109        | 249        | 0.3134, 0.3288 |      | none    | none   | 66013452         | Yes        |
| 14 | Extended color light | LCT002 | TV-Right-Lower       | On     | xy   | 36495 | 253        | 169        | 0.2868, 0.2762 | 153  | none    | none   | 66010673         | Yes        |
| 15 | Extended color light | LCT002 | Lab-Back-Left        | On     | xy   | 40723 | 252        | 239        | 0.2399, 0.1834 | 500  | none    | none   | 66010673         | Yes        |
| 16 | Dimmable light       | LWB004 | Kitchen-04           | Off    |      |       |            | 254        |                |      | none    |        | 66012040         | Yes        |
| 17 | Extended color light | LCT002 | Bed-Left-Upper       | On     | xy   | 41106 | 252        | 144        | 0.2356, 0.1749 | 500  | none    | none   | 66010673         | Yes        |
| 18 | Extended color light | LCT002 | Lab-Middle-Left      | On     | xy   | 36139 | 254        | 219        | 0.2904, 0.2837 | 153  | none    | none   | 66010673         | Yes        |
| 19 | Extended color light | LCT002 | Lab-Front-Left       | On     | xy   | 38320 | 253        | 193        | 0.2663, 0.2358 | 153  | none    | none   | 66013452         | Yes        |
| 20 | Extended color light | LCT002 | Bed-Right-Upper      | On     | xy   | 34486 | 237        | 215        | 0.3138, 0.3243 | 153  | none    | none   | 66010673         | Yes        |
| 21 | Extended color light | LCT002 | Bed-Center-Upper     | On     | xy   | 39407 | 253        | 168        | 0.2541, 0.2117 | 153  | none    | none   | 66010673         | Yes        |
| 22 | Extended color light | LCT002 | Library-Middle       | On     | hs   | 38256 | 253        | 238        | 0.2670, 0.2372 | 153  | none    | none   | 66010673         | Yes        |
| 23 | Extended color light | LCT002 | Library-Front        | On     | xy   | 40881 | 253        | 237        | 0.2376, 0.1791 | 500  | none    | none   | 66013452         | Yes        |
| 24 | Dimmable light       | LWB004 | Kitchen-05           | Off    |      |       |            | 254        |                |      | none    |        | 66012040         | Yes        |
| 25 | Dimmable light       | LWB004 | Kitchen-06           | Off    |      |       |            | 254        |                |      | none    |        | 66012040         | Yes        |
| 26 | Extended color light | LCT002 | Lab-Front-Right      | On     | xy   | 38541 | 253        | 236        | 0.2638, 0.2309 | 153  | none    | none   | 66010673         | Yes        |
| 27 | Extended color light | LCT002 | Lab-Middle-Right     | On     | xy   | 40714 | 252        | 235        | 0.2400, 0.1836 | 500  | none    | none   | 66010673         | Yes        |
| 28 | Extended color light | LCT002 | Lab-09               | On     | xy   | 35470 | 253        | 221        | 0.2982, 0.2989 | 153  | none    | none   | 66010673         | Yes        |
| 29 | Dimmable light       | LWB004 | Lux Lamp 2           | Off    |      |       |            | 254        |                |      | lselect |        | 66012040         | No         |
| 30 | Extended color light | LCT002 | Lab-06               | On     | xy   | 40862 | 252        | 135        | 0.2384, 0.1803 | 500  | lselect | none   | 66010673         | Yes        |
| 31 | Dimmable light       | LWB004 | Lux Lamp 3           | Off    |      |       |            | 254        |                |      | lselect |        | 66012040         | No         |
| 32 | Dimmable light       | LWB004 | Lux Lamp 4           | Off    |      |       |            | 254        |                |      | none    |        | 66012040         | No         |
| 33 | Color light          | LST001 | Library-Back         | On     | xy   | 40451 | 207        | 235        | 0.2029, 0.2472 |      | lselect | none   | 66013452         | Yes        |
| 34 | Color light          | LST001 | TV-Center            | On     | xy   | 41311 | 166        | 161        | 0.2475, 0.2632 |      | none    | none   | 66013452         | Yes        |
| 35 | Extended color light | LCT002 | Bedroom-Right-Upper  | On     | xy   | 34750 | 205        | 186        | 0.3204, 0.3266 | 164  | none    | none   | 66010673         | Yes        |
| 36 | Extended color light | LCT002 | Bedroom-Right-Middle | On     | xy   | 38929 | 253        | 237        | 0.2595, 0.2223 | 153  | none    | none   | 66010673         | Yes        |
| 37 | Extended color light | LCT002 | Bedroom-Right-Lower  | On     | xy   | 39740 | 253        | 234        | 0.2504, 0.2044 | 153  | none    | none   | 66010673         | Yes        |
+----+----------------------+--------+----------------------+--------+------+-------+------------+------------+----------------+------+---------+--------+------------------+------------+
```

#### Light Settings

Whether addressing all lights, a group of lights, or an individual light, these parameters are available to you.

Note that some parameters will not be available if the light is off or if the light doesn't support the feature.  For example, you cannot set brightness when a light is off, and you cannot set hue/saturation on a Hue Lux bulb as it doesn't support color.

All parameters are optional and can be mixed/matched as you see fit.

* `on` / `off`: Switch lights on or off.
* `--hue <H>`: Set the hue in HSB color space.  `<H>` goes from 0-65535 with red at 0.
* `--saturation <S>`: Set the saturation in HSB color space.  `<S>` goes from 0-255 but the bridge seems to clamp it to 254.  0 is white, and 255 is pure color.
* `--brightness <B>`: Set the brightness of the light.  `<B>` goes from 0-255 but the bridge seems to clamp it to 254.  0 is the lowest brightness the light supports, and 255 is the highest brightness.
* `--alert <MODE>`: Enable or disable a mode in which lights flash (change in brightness).
    * `select`: Flash once.
    * `lselect` Flash in a continous loop.
    * `none`: Stop flashing after having set `lselect`.
* `--effect <MODE>`: Enable special behaviors supported by the firmware.  At the time of this writing, they are:
    * `colorloop`: Cause the lights to cycle their hue in a continuous loop.
    * `none`: Stop looping through the hue wheel after having set `colorloop`.
* `--transitiontime <N>`: Cause a change to hue/saturation/brightness to be applied over the specified number of seconds.  Defaults to 0.4.  A value of 0 causes the change to be applied instantly.  The bridge supports a precision of tenths of a second, so don't bother with digits past the first one to the right of the decimal.

#### Manipulating All Lights: `hue all`

This sub-command lets you manipulate all lights at once.  All parameters are optional.

```bash
hue all off
hue all on --hue 45000 --brightness 127 --saturation 254 --transitiontime 0.1
hue all --alert lselect
hue all --alert none
hue all --effect colorloop
hue all --effect none
```

#### Manipulating A Light: `hue light`

This sub-command lets you manipulate a single light individually.  The numeric ID of the light (as reported by `hue lights`) is required.  All other parameters are optional.

In addition to the parameters supported by `hue all`, you can also set the name of the light:

* `--name "New Name"`

```bash
hue light 1 off
hue light 1 on --hue 45000 --brightness 127 --saturation 254 --transitiontime 0.1
hue light 1 --alert lselect
hue light 1 --alert none
hue light 1 --effect colorloop
hue light 1 --effect none
hue light 1 --name "New Name"
```

#### Creating a Group: `hue create_group`

This sub-command creates a group on the bridge.  At least one light ID (as reported by `hue lights`) must be specified.  It is your responsibility to ensure the name is unique.

```bash
hue create_group "My Group" 1 2 3
```

### Destroying a Group: `hue destroy_group`

This sub-command removes a group from the bridge.  The numeric ID of the group (as reported by `hue groups`) is required.

```bash
hue destroy_group 1
```

### Manipulating a Group: `hue group`

This sub-command sets the properties of several lights at once.

In addition to the parameters supported by `hue light`, you can also set which lights are in the group:

* `--lights "<id>,<id>..."


### Ruby

At present, the Ruby API is rather messy and awkward.  Look at `lib/hue/cli.rb` for usage examples.

```ruby
client          = FluxHue::Client.new
# Or:
client          = FluxHue::Client.new("<bridge_username>", "<bridge_ip>")

bridges         = client.bridges
default_bridge  = client.bridge
```

#### Lights

```ruby
light = client.lights.find { |ll| ll.reachable? }
# Or:
light = client.light(id)

# Change parameters of a light (one API request per statement!):
light.on!
light.hue = 46920
light.color_temperature = 100

# To change multiple parameters in a single API request:
light.set_state({ hue: 46920, brightness: 255 })

# To change one or more parameters over a specified interval (default is 0.4
# seconds -- note that Hue transition times are clamped to 1/10th of a second):
light.set_state({ hue: 46920, brightness: 255 }, 5.0)
```

#### Groups

``` ruby
group = client.groups.first
# Or:
group = client.group(1)

# Accessing lights in the group:
group.lights.first.on!
group.lights.each do |light|
  light.hue = rand(FluxHue::Light::HUE_RANGE)
end

# Manipulating a group at once:
group.hue = rand(FluxHue::Light::HUE_RANGE)

# And just like with lights you can make multiple changes in a single request:
group.set_state(hue: rand(FluxHue::Light::HUE_RANGE), brightness: 255)

# Creating groups
group         = Group.new(client)

group.name    = "My Group"
group.lights  = [3, 4]
group.new? # => true
result        = group.create!
if result.is_a?(Fixnum)
  # Success, yay!
  puts "Your new group has ID: #{result}"
  group.new? # => false
else
  # Error!  Boo!
  puts "Something went wrong: #{result.inspect}"
  # _TODO: Ensure `group.new?` returns true here!_
end

# Destroying groups
client.groups.last.destroy!
```

## Contributing

See the [contributing guide](CONTRIBUTING.md).
