Warning! Ki is currently not ready for public use. APIs, classes and functionality will change.

# Setting up development environment

Follow the instructions here: {file:docs/development_setup.md}

# Writing extensions

{file:docs/writing_extensions.md} describes how to extend Ki by writing extension scripts.

# Important Ruby classes

## Command line utilities

* {Ki::KiCommand} - Main ki entry point
* {Ki::KiCommandHelp}, {Ki::KiInfoCommand} - help, ki-info
* {Ki::UserPrefCommand} - Stored preferences
* {Ki::BuildVersionMetadataFile}, {Ki::TestVersion}, {Ki::ImportVersion}, {Ki::ExportVersion}, {Ki::VersionStatus}, {Ki::ShowVersion}, {Ki::VersionSearch} - repository management

## Data storage - files and directories

* {Ki::KiHome}, {Ki::Repository::Repository}, {Ki::Repository::Component}, {Ki::Repository::Version} - Repository directory objects
* {Ki::VersionMetadataFile}, {Ki::Dependency}, {Ki::VersionStatusFile} - Version metadata and statuses
* {Ki::DirectoryBase} - Base class for file and directory management
* {Ki::KiJSONFile}, {Ki::KiJSONListFile}, {Ki::KiJSONHashFile}, {Ki::KiJSONHashFile::CachedMapDataAccessor} - Base classes for JSON files
* {Ki::DirectoryWithChildrenInListFile} - Helper to generate list file class and related methods for a repository object
* {Ki::RepositoryMethods}, {Ki::RepositoryMethods::RepositoryListFile} - Repository helper methods
* {Ki::UserPrefFile} - Stored preferences

## Data access - finders, helpers, iterators

* {Ki::VersionTester}, {Ki::VersionImporter}, {Ki::VersionExporter} - Utility classes for managing version
* {Ki::RepositoryFinder} - Loads components from all available repositories and finds components and versions
* {Ki::VersionIterator} - Provides method to iterate through all component's matching versions
* {Ki::FileFinder} - Finds matchins files from a Version
* {Ki::Component}, {Ki::Version} - Classes that manage combined information for versions and components from all repositories
* {Ki::VersionFileOperations} - Helper class to process Version's file operations

## Utilities

* {Ki::Tester} - Helper class for tests, makes it easy to clear resources
* {AttrChain} - Chained accessor methods
* {ExceptionCatcher} - Execute multiple blocks and process exceptions in the end
* {Ki::ServiceRegistry} - Class for storing all Ki extensions
* {Ki::SimpleOptionParser} - Simplified OptionParser
