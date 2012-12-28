# @title Ki: Command line utilities
# Command line utilities for Ki Repository v0.1.1
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

note: By default only files with tag "ki-cmd" are used. Use the 'my/tools:scripts,tools' to define additional tags.

Common parameters:

    -h, --home                       Path to Ki root directory
    -u, --use                        Use defined scripts
        --require                    Require Ruby files
        --load                       Load Ruby files

## help: Displays help for given Ki command

"ki help" shows information Ki and its commands.

### Examples

    ki help
    ki help version-build

## ki-info: Show information about Ki

"ki ki-info" shows information about Ki.

### Examples

    ki ki-info -c
    ki ki-info -r

### Parameters
    -c, --commands                   List commands
    -r, --registered                 List all registered extensions

## version-build: Create version metadata file

"ki version-build" can be used to generate version metadata files. Version metadata files
contain information about files (size, permission bits, hash checksums), version origins
and dependencies.

After version metadata file is ready, it can be imported to repository using version-import.

### Usage

    ki version-build <parameters> file_pattern1*.* file_pattern2*.*

### Examples

    ki version-build test.sh
    ki version-build readme* -t doc
    ki version-build -d my/component/1,name=comp,path=doc,internal -O "mv doc/test.sh helloworld.sh"
    ki version-import

### Parameters

    -f, --file FILE                  Version file target
    -i, --input-directory INPUT-DIR  Input directory
    -v, --version-id VERSION-ID      Version's id
        --source-url URL             Build source parameter url
        --source-tag-url TAG-URL     Build source parameter tag-url
        --source-author AUTHOR       Build source parameter author
        --source-repotype REPOTYPE   Build source parameter repotype
    -t, --tags TAGS                  Tag files with keywords
        --hashes HASHES              Calculate checksums using defined hash algos. Default: sha1. Available: sha1, sha2, md5
    -d, --dependency DEPENDENCY      Dependency definition my/component/123[,name=AA][,path=aa][,internal]
    -o, --operation OP               Add operation to previous dependency
    -O, --version-operation OP       Add operation to version


## version-test: Tests versions and their dependencies

"ki version-test" tests versions, their files and their dependencies. Can also test version that has not been imported yet.

### Examples

    ki version-test -r my/product other/product
    ki version-test -f ki-version.json -i file-directory

### Parameters

    -f, --file FILE                  Version source file. By default uses file's directory as source for binary files.'
    -i, --input-directory INPUT-DIR  Binary file input directory
    -r, --recursive                  Tests version's dependencies also.'


## version-import: Imports version metadata and files to repository

"ki version-import" imports version and its files to repository.

Version name can be defined either during "version-build",
or generated automatically for component at import (with -c my/component) or defined to be a specific version (-v).
Can also move files (-m), test dependencies before import (-t).

### Examples

    ki version-import -m -t -c my/product
    ki version-import -f ki-version.json -i file-directory

### Parameters

    -f, --file FILE                  Version source file. By default uses file's directory as source for binary files.'
    -i, --input-directory INPUT-DIR  Input directory
    -t, --test-recursive             Tests version's dependencies before importing.'
    -m, --move                       Moves files to repository'
    -c COMPONENT,                    Creates new version number for defined component'
        --create-new-version
    -v, --version-id VERSION         Imports version with defined version id'


## version-export: Export version to a directory

"ki version-export" exports version and its dependencies to target directory.

### Usage

    ki version-export <parameters> <file_export_pattern*.*>

### Examples

    ki version-export -o export-dir --tags -c bin my/product
    ki version-export -o scripts -c -t my/admin-tools '*.sh'

### Parameters

    -o, --output-directory INPUT-DIR Input directory
        --tags TAGS                  Select files with matching tag
    -t, --test                       Test version before export
    -c, --copy                       Exported files are copied instead of linked


## version-status: Add status values to version

"ki version-status" sets status values to versions and sets status value order to component.

Status value order is used to determine which statuses match version queries:

    my/component:maturity>alpha

### Examples

    ki version-status add my/component/1.2.3 Smoke=Green action=path/123
    ki version-status order my/component maturity alpha,beta,gamma

## version-show: Prints information about version or versions

"ki version-show" prints information about version or versions and their dependencies

### Examples

    ki version-show -r -d my/component/23 my/product/127
    ki version-show -f ki-version.json -i binary-dir

## version-search: Searches for versions and components

"ki version-search" searches for versions and components.

### Examples

    ki version-search my/component
    ki version-search my/*

## pref: Sets user preferences

Sets user preferences
Syntax: ki pref prefix|use parameters...

### Examples for command prefixes:
    ki pref prefix
    - shows command prefixes, when a "ki command" is executed ki looks for the command with all prefix combinations
    ki pref prefix version package
    - sets two command prefixes, looks for "command", "version-command" and "package-command"
    ki pref prefix + foo
    - adds one command prefix to existing ones, looks for "command", "version-command", "package-command", "foo-command"
    ki pref prefix - package foo
    - removes two command prefixes from list
    ki pref prefix -c
    - clears command prefix list

### Examples for default script loading:
    ki pref use
    - shows list of automatically loading scripts. when ki starts up, it looks for all defined versions and loads all files tagged with ki-cmd
    ki pref use ki/http ki/ftp/123:ki-extra
    - scripts are loaded from two different version. ki/http uses latest available version and files tagged with "ki-cmd", ki/ftp uses specific version and files tagged with "ki-extra"
    ki pref use + ki/scp
    - adds one more script package version
    ki pref use - ki/scp ki/ftp/123:ki-extra
    - removes two configurations
    ki pref use -c
    - clear use list

### Examples for default Ruby file requiring:
    ki pref require
    ki pref require hooves/default
    ki pref require + hooves/default
    ki pref require - hooves/default
    ki pref require -c

### Examples for default Ruby file loading:
    ki pref load
    ki pref load test.rb
    ki pref load + test.rb
    ki pref load - test.rb
    ki pref load -c

## web: Starts Ki web server and uses code from Ki packages

ki-repo has a built in web server. It can be controlled with following commands
  ki web
