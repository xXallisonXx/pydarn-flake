# pydarn-flake
Nix flake for SuperDARN's visualisation library PyDARN.

Before use, please be aware of two things:

1) PyDARN pulls hardware files from https://github.com/SuperDARN/hdw upon use. Since nix makes dpendencies read-only, PyDARN cannot...
   Therefore, this flake pins the hdw files at this commit: https://github.com/SuperDARN/hdw/commit/41225eccd5b683b2f5a4ffe21a50249de9e46d02.
   Newer or older hdw versions can be updated inside the flake itself.

2) As per https://github.com/SuperDARN/pydarn/commit/ce32ba2e4da51f4d76230ea36fec899c0abb9b84, PyDARN throws a flag if scipy is newer than 1.14 because of a contour plot bug. I am ignoring this in hopes that it will be resolved soon...


This includes support for two PyDARN dependencies, AACGMV2 and PyDARNio.
To build place in directory of project and 
nix build .#py
