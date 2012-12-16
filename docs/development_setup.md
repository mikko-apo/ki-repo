# @title Ki: Setting up development environment
# Setting up development environment

## Install Ruby 1.9

Rvm makes it easy to use multiple ruby installations. By default it installs rubies to users home directory.
Rvm is available at http://beginrescueend.com/

Follow the rvm installation instructions, once the rvm command line tool works execute:

    rvm install 1.9.2
    rvm use 1.9.2
    rvm gemset create ki
    rvm use 1.9.2@ki

Now ruby 1.9.2 should be available and all gems will be installed for Ki use only.

## Check out the source

    git clone git@github.com:mikko-apo/ki-repo.git
    cd ki-repo

## Install gems

Bundler is used to download and install the required gems to the ruby environment in use. if you are using rvm, gems are installed to rvm's directories.

    gem install bundler
    bundle install

## Run tests

Tests are run with

    rake spec

All tests should pass. Code coverage report is generated to coverage/index.html

## Generate documentation

Documentation is generated to doc/index.html with

    rake yard

You can also start up the yard in server mode, which makes it easier to update the documentation. When server starts
up, the documentation will be available at http://localhost:8808/

    yard server --reload


