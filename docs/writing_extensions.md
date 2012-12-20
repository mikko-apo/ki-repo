# @title Ki: Writing extensions

Ki can be extended by packaging extension code in to version packages and using the `ki -u version/id` command line
parameter to load scripts in to the Ruby VM. Extension versions can also be configured to be automatically loaded
with the `ki pref prefix version/id`.

Ki's extension mechanism makes it easy to manage different scenarios:
* write and distribute command line utilities
* use different versions of those utilities at the same time on the same machine (backwards compatability)
* add new features to existing utilities: hashing algorithms, integrations to different tools like git, mercurial and svn

Ki-Flow, an advanced CI system is implemented as Ki extensions. It heavily extends Ki by adding new command line tools,
a fully functional web site and web interface and lots

# Command line utility

# Extension points
*