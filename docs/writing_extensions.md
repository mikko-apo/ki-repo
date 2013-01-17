# @title Ki: Writing extensions

# Writing extensions

Ki can be extended by packaging extension code in to version packages and using the `ki -u version/id` command line
parameter to load scripts in to the Ruby VM. Extension versions can also be configured to be automatically loaded
with the `ki pref prefix version/id` command.

"ki" is the main command line tool that starts all other Ki processes. Whenever ki command line tools
are executed, ki goes through the following startup process

1. Common command line parameters are parsed. These can used to set execution parameters for this invocation.
2. Extension scripts are loaded from repository. Version configuration is from either -u or user preferences
3. Find command by name
4. Execute the command and pass rest of the command line parameters

Examples

    ki build-version *.txt
    ki -u my/tools compile
    ki -u my/tools:scripts,tools compile

note: By default only files with tag "ki" are used. Use the 'my/tools:scripts,tools' to define additional tags.

Ki's extension mechanism makes it easy to manage different scenarios:
* write and distribute command line utilities
* use different versions of those utilities at the same time on the same machine (backwards compatability)
* add new features to existing utilities: hashing algorithms, integrations to different tools like git, mercurial and svn

# Extension points

{Ki::KiCommand} stores all registered extensions to its class variable {Ki::KiCommand::KiExtensions} ({Ki::ServiceRegistry}).

Currently used extension points are:

* /commands/
* /hashing/
* /web/

## Command line utility - /commands/

Command classes are registered with KiCommand.register_cmd

    KiCommand.register_cmd("version-build", BuildVersionMetadataFile)

They should implement following methods:
* execute(ctx, args)
* help, summary
* attr_chain :shell_command, :require is optional but help method can use it to generate more useful help texts

For more information, see {Ki::ImportVersion}

## Cryptographic hash functions - /hashing/

Classes used for hashing must implement class method digest which returns a class extending Digest::Class

For more information, see {Ki::SHA2} and {Digest::SHA2}

## Web classes - /web/

Ki-repo includes support for running web applications. Web applications are created by creating Rack application classes
and tagging each file containing classes with "ki". That way "ki" command loads files and {Ki::RackCommand} starts
web application from classes that were loaded. Each class is registered to the path remaining from registration key:

    KiCommand.register("/web/test", MyApp2)

For more information, see {Ki::RackCommand}