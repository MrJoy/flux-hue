# To Do

* RGB translation
* Hex translation
* Scheduling
* Effects
* User management
* Configuration
* Make a class to represent XY color and normalize how the attribute is handled in EditableState.
* More robust color tools, starting from: https://github.com/sshao/hue
* Use an HTTP lib that allows us to use keepalives, if the bridge supports it.
    * Try: https://rubygems.org/gems/persistent_httparty
    * See: http://www.slideshare.net/HiroshiNakamura/rubyhttp-clients-comparison (slides 14, 22, 30, )
        * Short form:  Curb has parallel requests, keepalives AND pipelining but check current JRuby compatibility.
* Machine-friendly output format.
* Separate output into STDOUT for data and STDERR for logging.  Maybe even use a proper logger!
* Support for scenes.
* Address lights/groups/etc symbolically wherever they can be addressed.
    * Need to prohibit duplicate names, and warn if we see duplicates!
* Explicit username is deprecated.  Allow bridge to assign us one, report it to the user, and pick it up from an env var / config file / something.
* Push more functionality from CLI into API for simplicity of usage...
* Add a mode to allow the bridge to assign the user ID, since explicit IDs are deprecated!
* Add commands to look at sensors.  Maybe have a way to wait on particular sensors?
* Add commands to manipulate bridge configuration.
* Add configuration file mechanism to associate user IDs with each encountered bridge.
* Add options for machine-readable output to all commands.
* At present, there exists some code for scenes, but it's not exposed in the CLI.
* Automatic retries+backoffs and parameters for controlling this behavior, because OHGODRATELIMITS.
* Check the docs for further constraints on user.
* Expose color mode / color temperature / X+Y parameters to CLI.
* Is there a way we can tell the bridge to address all lights in a single API request?  Because OHGODRATELIMITS!
* Link to Philips documentation about color spaces and give a tl;dr about the complexity of the topic.
* Make `order` more friendly by making indexing 1-based, and allowing named column references.
* Maybe add some statically-defined metadata from the docs about whitepoint and color ranges based on device type?
* See if brightness/saturation limit of 254 is a rounding issue associated with HS color mode.
