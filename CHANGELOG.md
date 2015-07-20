# Changes

## Upcoming

* Significant overhaul from underlying source code to better separate concerns.
* Improved performance for CLI for most use-cases.
    * Don't fetch/parse the entire system state just to validate username.
    * Don't load SSDP code unless/until it's needed.
    * Streamline dependencies and code loading slightly to reduce overhead.
* SSDP discovery (no Internet connection needed, but slower / less reliable).
* Better ability to work with multiple hubs.
    * Ability to discover and list all hubs.
    * Ability to see more details about each hub.
* Working functionality for managing groups from CLI.
* More informative output for `hue groups`, and `hue lights`.
