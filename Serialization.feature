
Feature: Serialize Hashtables or Custom Objects
    To allow users to configure module preferences without editing their profiles
    A PowerShell Module Author
    Needs to serialize a preferences object in a user-editable format we call metadata

    @Serialization
    Scenario: Serialize a hashtable to string
        Given a settings hashtable
            """
            @{ UserName = "Joel"; BackgroundColor = "Black"}
            """
        When we convert the settings to metadata
        Then the string version should be
            """
            @{
              UserName = 'Joel'
              BackgroundColor = 'Black'
            }
            """

    @Serialization
    Scenario: Should be able to serialize core types:
        Given a settings hashtable with a String in it
        When we convert the settings to metadata
        Then the string version should match 'TestCase = ([''"])[^\1]+\1'

        Given a settings hashtable with a Boolean in it
        When we convert the settings to metadata
        Then the string version should match 'TestCase = \`$(True|False)'

        Given a settings hashtable with a NULL in it
        When we convert the settings to metadata
        Then the string version should match 'TestCase = ""'

        Given a settings hashtable with a Number in it
        When we convert the settings to metadata
        Then the string version should match 'TestCase = \d+'

    @Serialization
    Scenario: Should be able to serialize a array
        Given a settings hashtable with an Array in it
        When we convert the settings to metadata
        Then the string version should match 'TestCase = ([^,]*,)+[^,]*'

    @Serialization
    Scenario: Should be able to serialize nested hashtables
        Given a settings hashtable with a hashtable in it
        When we convert the settings to metadata
        Then the string version should match 'TestCase = @{'


    @Serialization
    Scenario Outline: Should support a few additional types
        Given a settings hashtable with a <type> in it
        When we convert the settings to metadata
        Then the string version should match "TestCase = <type> "

        Examples:
            | type           |
            | DateTime       |
            | DateTimeOffset |
            | GUID           |
            | PSObject       |

    @Serialization @Enum
    Scenario: Unsupported types should be serialized as strings
        Given a settings hashtable with an Enum in it
        Then we expect a warning
        When we convert the settings to metadata
        And the warning is logged

    @Serialization @Error
    Scenario: Invalid converters should write non-terminating errors
        Given we expect an error
        When we add a converter that's not a scriptblock
        And we add a converter with a number as a key
        Then the error is logged exactly 2 times

    @Serialization @Uri
    Scenario: Developers should be able to add support for other types
        Given a settings hashtable with a Uri in it
        When we add a converter for Uri types
        And we convert the settings to metadata
        Then the string version should match "TestCase = Uri '.*'"

    @Deserialization @Uri
    Scenario: I should be able to import serialized data
        Given a settings hashtable 
            """
            @{
              UserName = 'Joel'
              Age = 42
              LastUpdated = (Get-Date).Date
              Homepage = [Uri]"http://HuddledMasses.org"
            }
            """
        Then the settings object should have an Homepage of type Uri
        And we add a converter for Uri types
        And we convert the settings to metadata
        When we convert the metadata to an object
        Then the settings object should be a hashtable
        Then the settings object should have an UserName of type String
        Then the settings object should have an Age of type Int32
        Then the settings object should have an LastUpdated of type DateTime
        Then the settings object should have an Homepage of type Uri

    @Deserialization @Uri
    Scenario: I should be able to import serialized data even in PowerShell 2
        Given a settings hashtable 
            """
            @{
              UserName = 'Joel'
              Age = 42
              LastUpdated = (Get-Date).Date
              Homepage = [Uri]"http://HuddledMasses.org"
            }
            """
        And we fake version 2.0 in the Metadata module
        And we add a converter for Uri types
        And we convert the settings to metadata
        When we convert the metadata to an object
        Then the settings object should be a hashtable
        Then the settings object should have an UserName of type String
        Then the settings object should have an Age of type Int32
        Then the settings object should have an LastUpdated of type DateTime
        Then the settings object should have an Homepage of type Uri

    @Deserialization
    Scenario: I should be able to import serialized data from files even in PowerShell 2
        Given a settings file 
            """
            @{
              UserName = 'Joel'
              Age = 42
            }
            """
        And we fake version 2.0 in the Metadata module
        When we convert the file to an object
        Then the settings object should be a hashtable
        Then the settings object should have an UserName of type String
        Then the settings object should have an Age of type Int32

    @Deserialization
    Scenario: Imported metadata files should be able to use PSScriptRoot
        Given a settings file 
            """
            @{
              MyPath = "$PSScriptRoot\Settings.psd1"
            }
            """
        And we're using PowerShell 4 or higher in the Metadata module
        When we convert the file to an object
        Then the settings object should be a hashtable
        And the settings object should have a MyPath of type String
        And the settings object MyPath should match the file's folder

