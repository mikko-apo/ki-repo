# @title Ki: Backlog

# Backlog for 0.2
* fix defined? checks
* fix double repository entries in finder.all_repositories "should show imported version"
* cleanup gem
* document script usage
* create release notes

# 0.2.1
* cleanup and removal operations
* version() returns sometime nil, sometimes Version
* version!()
* fix Version.exists? - there should be a better way to check if version exists
* VersionTester should support test_version(metadata, source)
* Download & replication
* support for separate binaries directory
* website command
* daemon

# Future releases...
* Digital signing
* Encrypted/packed packages
* Support for using files from other repositories
* when building version create file operations based on user's changes

# Maybe at some point...
* replace popen4.spawn with Kernel.spawn
* alias
* package dep operations: dep-rm, dep-mv, dep-cp, dep-switch
* named version lists for component my/component#released:Smoke=green

# Future backwards compatability issues
* how to store version directories so that per directory limits can be bypassed