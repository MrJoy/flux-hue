# To Do

* RGB translation
* Hex translation
* Scheduling
* Effects
* User management
* Configuration
* Use `Curb::Multi` for making multiple changes at once?
* Look into HTTP KeepAlive for lower latency on changes?
* Ability to create a group from CLI / more easily from the API.
* Ability to address groups by name uniformly.
* Allow symbolic names instead of IDs
* Ensure names don't collide.
* Make a class to represent XY color and normalize how the attribute is handled in EditableState.
* More robust color tools, starting from: https://github.com/sshao/hue
* Allow an env var for specifying IP, and add a command to find *all* hubs on the network.
* Use an HTTP lib that allows us to use keepalives, if the hub supports it.
    * Try: https://rubygems.org/gems/persistent_httparty
    * See: http://www.slideshare.net/HiroshiNakamura/rubyhttp-clients-comparison (slides 14, 22, 30, )
        * Short form:  Curb has parallel requests, keepalives AND pipelining but check current JRuby compatibility.
