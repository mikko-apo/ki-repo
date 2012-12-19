# Command line utilities for Ki Repository v0.1.0

Common parameters:

    -h, --home                       Path to Ki root directory
    -u, --use                        Use defined scripts

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


## version-test: Tests version's files if they are intact.

Test

    -f, --file FILE                  Version source file. By default uses file's directory as source for binary files.'
    -i, --input-directory INPUT-DIR  Binary file input directory
    -r, --recursive                  Tests version's dependencies also.'

## version-import: Imports version metadata and files to repository

Test

    -f, --file FILE                  Version source file. By default uses file's directory as source for binary files.'
    -i, --input-directory INPUT-DIR  Input directory
    -t, --test-recursive             Tests version's dependencies before importing.'
    -m, --move                       Moves files to repository'
    -c COMPONENT,                    Creates new version number for defined component'
        --create-new-version
    -v, --version-id VERSION         Imports version with defined version id'

## version-export: Export version to a directory

Test

    -o, --output-directory INPUT-DIR Input directory
        --tags TAGS                  Select files with matching tag
    -t, --test                       Test version before export
    -c, --copy                       Exported files are copied instead of linked

## version-status: Add status values to version

Test

## version-show: Prints information about version or versions

Test

    -r, --recursive                  Shows version's dependencies.'
    -d, --dirs                       Shows version's directories.'
    -f, --file FILE                  Version source file. By default uses file's directory as source for binary files.'
    -i, --input-directory INPUT-DIR  Binary file input directory

## version-search: Searches for versions and components

Test

## pref: Sets user preferences

Sets user preferences
Syntax: ki pref prefix|use parameters...

Examples for command prefixes:
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

Examples for automatic script loading:
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

