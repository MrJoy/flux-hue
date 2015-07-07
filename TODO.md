# To Do

* RGB translation
* Hex translation
* Scheduling
* Effects
* User management
* Configuration
* Make a class to represent XY color and normalize how the attribute is handled in EditableState.
* More robust color tools, starting from: https://github.com/sshao/hue
* Use an HTTP lib that allows us to use keepalives, if the hub supports it.
    * Try: https://rubygems.org/gems/persistent_httparty
    * See: http://www.slideshare.net/HiroshiNakamura/rubyhttp-clients-comparison (slides 14, 22, 30, )
        * Short form:  Curb has parallel requests, keepalives AND pipelining but check current JRuby compatibility.
* Machine-friendly output format.
* Separate output into STDOUT for data and STDERR for logging.  Maybe even use a proper logger!
* Support for scenes.
* Address lights/groups/etc symbolically wherever they can be addressed.
    * Need to prohibit duplicate names, and warn if we see duplicates!
* Explicit username is deprecated.  Allow hub to assign us one, report it to the user, and pick it up from an env var / config file / something.
* Push more functionality from CLI into API for simplicity of usage...
