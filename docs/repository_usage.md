# @title Ki: Repository

# Getting started

1. Create a version and import it to repository

    echo "Hello World!" > test.sh
    echo "Simple demo" > "readme.txt"
    chmod u+x test.sh
    ki version-build test.sh
    ki version-build readme* -t doc
    ki version-import -m -c my/component
    ki version-show my/component

* version-import -c creates a new version under my/component and -m moves the files to version's repository directory
* version-show looks for the latest available version and shows information about that

2. Create another version, with dependency to my/component/1 and import that too

    ki pref prefix version
    ki build -d my/component/1,name=comp,path=doc,internal -O "mv doc/test.sh helloworld.sh"
    ki import -m -c my/product
    ki show -r my/product
    ki export my/product export
    find export

* "ki pref prefix version" configures a shortcut to call version commands with shorter syntax
* version-build generates a dependency to my/component/1 and puts the files from my/component/1 to doc directory
* version-build -O operations are executed when the product version is exported, doc/test.sh is moved to helloworld.sh
* the contents of "export" directory should be:

    export/doc/readme.txt
    export/helloworld.sh

# Repository basics

## Repository structure: components, versions

Ki-Repo is a repository for storing file packages and metadata about those packages. A repository has following structure

    repository/
      my/component/
        23/
          jar/lib.jar
          readme.txt
          start.sh
        22/
          jar/lib.jar
          readme.txt
          start.sh
        21/
          jar/lib.jar
          readme.txt
          start.sh
      my/componentB/
        build-211/
          lib/utils.rb
        build-210/
        build-209/
        ...
      my/product/
        product-97/
        product-98/
        ...

Repository maintains a list of components: "my/componentA", "my/componentB", "my/product".

Component maintains a chronological list of versions: "build-3", "build-2", "build-1".
Component's name should be a unique identifier and it can include any number of identifiers. Valid component names
include "ki/repo", "ki-repo", "my/test/builds/ki/repo/".

Version contains a set of files. Version can also define dependencies and other metadata.

The repository structure is very close to the actual directory structure.

## Version

Each version identifies a unique combination of files and dependencies. After version has been built and imported to
repository it does not change. This ensures that when ever the version is used, the contents stay the same.

In addition to having files, version can define metadata about its files (size, permission bits, hash checksums), origins and dependencies.
Files can also be tagged with identifiers to make it easier to identify files of different types. Versions can also have status
information (for example "IntegrationTest=green"), which makes it easier to search for versions.

Version's full name is the name of the component and the version name: my/component/23

### File metadata

    { "path": "test.sh", "size": 2, "executable": true, "tags": [ "test-start" ], "sha1": "9a900f538965a426994e1e90600920aff0b4e8d2" }

* path identifies the actual file (stored in the version)
* size and sha1 are calculated when version is built
* executable is stored when version is built and ki ensures that when the file is in repository or exported is has its executable flag set on
* file tags can be used to tag files with different identifiers

### Source information

    { "url": "http://test.repo/component@21331", "tag-url": "http://test.repo/component/tags/23", "repotype": "git", "author": "john" }

* source information is used to store reference to the original source of the package

### Dependencies

Version can have dependencies, that include additional versions in to the main version. Dependencies refer to other
versions with full version name.

        { "version_id": "my/component/23", "name": "comp", "path": "comp", "internal": true,
          "operations": [
            [
              "cp", "comp/test.sh", "test.bat"
            ]
          ]
        }

* version_id defines the full name of the required version
* path defines a subdirectory where files from this dependency are placed
* dependency can have a name, which makes it possible to compare version's dependencies and also navigate version hierarchies
** navigation syntax: my/product/1>comp -> my/component/1
** my/product/1>comp = my/component/23, my/product/2>comp -> my/component/24
* internal dependencies are visible in the version hierarchy only for top level version. comp is visible from my/product,
but if other version has a dependency on product, files from comp are not visible

### File Operations

Version can define file operations to modify the exported file structure. Operations can be defined at version level, so
that they affect version's all files (the ones defined in the version and brought by the dependencies). File operations
can also be defined per dependency.

Available file operations:
* cp - copy pattern1 pattern2 ... dest
* mv - move pattern1 pattern2 ... dest
* rm - remove.

Examples

    "rm *.txt"
    "cp *.txt sub-directory"
    "mv *.sh scripts"

# Command line utilities

## version-build
* Creates version metadata file. Possible to set source info, dependencies, files and operations.

## version-test
* Tests version's files if they are intact.

## version-import
* Imports version to local package directories

## version-export
* Export version to current directory or selected output directory

## version-status
* Add status to version to specified package info location

##  version-show
* Prints information about version or versions

##  version-search
* Searches for versions and components
