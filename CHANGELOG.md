# Changes

## Next

### Features:

* Clamp brightness when clamping saturation, as white light will necessarily be brighter than colored light.
* Allow per-bridge color sweeps.

### Fixes

* Slightly better handling of failures in `sparkle-motion`.  I.E. don't restart on *any* failure, just code 127.
* Slightly better handling of corrupted state file.
* Improve error-handling in helper tools (`sm-on`, `sm-off`, `sm-mark-lights`).
* Make base color used by `sm-on` configurable.  D'oh.
* Fix flooring of final brightness value.
* Fix error where the `Range` node treated its parameters as if they were ranged from 0..255, rather than 0..1.

### Refactoring:

* Tidy up notes/TODOs.
* Namespace more classes to reduce namespace pollution.


## 0.1.0 - 2015-09-12

* Initial release.  Totally undocumented, annoyingly hard-coded, etc.
