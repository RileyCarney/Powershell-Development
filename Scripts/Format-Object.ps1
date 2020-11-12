<# 
.SYNOPSIS Formats Object Types into PSCustomObject
.DESCRIPTION This Powershell script is utilized to transform object types dynamically into PSCustomObject.
The end goal of this is to transform objects into PSCustomObject, while retaining the original property information.
The script won't necessarily be quick for large pulls, but can be useful for smaller queries.
.NOTES This PowerShell script was developed by a scrub.
The customer or user is authorized to copy the script from the repository and use them in ScriptRunner. 
PowerShell is a product of Microsoft Corporation.
.LINK https://github.com/RileyCarney/Powershell-Development/blob/main/README.md
.Parameter Object The Object user is passing into function.
#>
function Format-Object {
        [CmdletBinding(DefaultParameterSetName='')]
    param(
        [Parameter(Mandatory=$false)]
        [Object]$object = $null
    )
    if ($null -eq $object) { # Base case, no object found
        return $null
    }

    # Class Definitions
    class dynamicProperty {
        [String]$Name = $null
        [String]$IsPublic = $null
        [boolean]$IsSerial = $false
        [boolean]$BaseType = $false
        [String]$PropertyName = $null
        dynamicProperty(
            [String]$Name,
            [String]$IsPublic,
            [boolean]$IsSerial,
            [boolean]$BaseType,
            [string]$PropertyName
        ) {
            $this.Name = $Name
            $this.IsPublic = $IsPublic
            $this.IsSerial = $IsSerial
            $this.BaseType = $BaseType
            $this.PropertyName = $PropertyName
        }
        dynamicProperty(
            [String]$PropertyName
        ) {
            $this.PropertyName = $PropertyName
        }
        dynamicProperty() {}
    }

    # Variable Definitions
    [System.Collections.ArrayList]$properties = @()
    $propertySchema = @{}

    # Get Object Properties
    $GetMemberProperties = $object | Get-Member | 
                                Where-Object {$_.MemberType -eq "Property"}
    if ($GetMemberProperties.count -eq 0) { # Base case, no properties found
        return $null
    }

    # Loop through Object Properties
    foreach ($property in $GetMemberProperties.Name) {
        if ($null -eq $object.$property) { # Base case, no object on property
            $tempProperty = [dynamicProperty]::new($property) # Make new property with just the name in property
            $properties.Add($tempProperty) | Out-Null
        }
        else { # If it is an object
            $propertyTypes = $object.$property.getType()
            $tempProperty = [dynamicProperty]::new($propertyTypes.Name, 
                                                    $propertyTypes.IsPublic, 
                                                    $propertyTypes.IsSerial, 
                                                    $propertyTypes.BaseType, 
                                                    $property) # Add property information to schema builder
            $properties.Add($tempProperty) | Out-Null # List for schema builder
        }
    }

    # Loop through property in schema builder
    foreach ($property in $properties) { 
        $propertySchema.add($property.PropertyName,$null) # Build property schema with empty values
        # TODO: More robust schema building, noting specific object classes etc.
    }
    $outputObject = [PSCustomObject]$propertySchema # Convert schema to PSCustomObject
    foreach ($property in $propertySchema.Keys) { # Loop through schema
        $outputObject.$property = $object.$property -join ";" # Array builder "hack"
        # TODO: more robust object building alongside schema
    }
    return $outputObject
}