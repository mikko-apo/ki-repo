# @title Ki: Backlog

# Backlog for 0.2
* fix defined? checks
* fix double repository entries in finder.all_repositories
* version() returns sometime nil, sometimes Version
* version!()
* fix Version.exists? - there should be a better way to check if version exists
* fix directory structure
* gem version stored as internally available version number (script backwards compatability)
* VersionTester should support test_version(metadata, source)
* cleanup gem
* cleanup and removal operations
* document script usage
* create release notes

# Future releases...
* website command
* Download & replication
* Digital signing
* Encrypted/packed packages
* Support for using files from other repositories
* when building version create file operations based on user's changes
* daemon
* support for separate binaries directory

# Maybe at some point...
* replace popen4.spawn with Kernel.spawn
* alias
* package dep operations: dep-rm, dep-mv, dep-cp, dep-switch
* named version lists for component my/component#released:Smoke=green

# Future backwards compatability issues
* how to store version directories so that per directory limits can be bypassed