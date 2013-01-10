# ki-repo

Repository for storing packages and metadata.

note: Currently Ki is not ready for any kind of use.

# Links

* Rubygem: https://rubygems.org/gems/ki-repo
* Documentation for latest released version is available at http://rubydoc.info/gems/ki-repo
* See also ki-flow, the advanced CI system: http://ki-flow.org and https://github.com/mikko-apo/ki-flow

# Documentation

* {file:docs/repository_basics.md Repository basics} includes a simple tutorial and explains basic concepts.
* Ki command line utilies are documented in {file:docs/ki_commands.md}.
* {file:docs/development.md Development} provides additional development related information.

# Plan

1. Local repository features: create package, import, export, list, test, dependencies
2. Metadata support: statuses, file tagging
3. Repository cleanup and removal
4. Use script files in repository to add additional commands to ki
5. Documentation

Once these features are implemented Ki is ready for use on local server. In the future, the goal is to provide tools
to manage distributed repositories: downloads and replication.

# Tech stack

* http://www.ruby-lang.org/en/

## Testing and documentation

* http://rspec.info/ - Test framework
* http://gofreerange.com/mocha - Ruby test mocking
* https://github.com/colszowka/simplecov - Test coverage
* http://yardoc.org/ - Yard documentation
* https://github.com/rtomayko/rdiscount - Markdown

## Web

* http://rack.github.com/ - Ruby web server support
* http://www.sinatrarb.com/ - Simple web application framework
* http://coffeescript.org/
* http://sass-lang.com/
* http://code.google.com/p/selenium/wiki/RubyBindings - Selenium WebDriver

# Copyright

Copyright (c) 2012 Mikko Apo. See {file:LICENSE.txt} for further details.

