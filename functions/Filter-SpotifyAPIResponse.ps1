function Filter-SpotifyAPIResponse {
    <#
        .SYNOPSIS
            Filter attributes from an API response.

        .DESCRIPTION
            The attributes in the given filter will be kept, other attributes will be removed from the response.
            You can drill down into nested objects using the notation: nested_object(attribute, attribute)
            For no filtering, use: '-Filter *'

        .PARAMETER Data
            The response from the Spotify API.

        .PARAMETER Filter
            A filter specifiying which attributes will be stored on disk.

        .INPUTS
    	    None. You cannot pipe input to Filter-SpotifyAPIResponse.

        .OUTPUTS
            A pscustomobject containing the filtered response.
    #>

    [CmdLetBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [pscustomobject] $Data,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $Filter
    )

    if($Filter -eq '*') {
        return $Data
    }

    $FilterObj = (BuildFilterObject -FilterString $Filter -OpenPos 0)[0]
    $FilteredData = FilterResponseObject -Data $Data -Filter $FilterObj

    return $FilteredData
}

function BuildFilterObject{
    <#
        Recursively builds a filter object. For each attribute in the filter string there will be a property
        named after the attribute created. For nested objects a nested filter object will be created.
    #>

    param([string] $FilterString, [int] $OpenPos)

    $Filter = @{}
    $Attribute = ''
    $ClosePos = $FilterString.Length

    for($ii = $OpenPos; $ii -lt $FilterString.Length; $ii++){
        if($FilterString[$ii] -eq ',') {
            if($Attribute) {    # prevent empty entry when , after )
                $Filter[$Attribute.trim()] = ''
                $Attribute = ''
            }
        } elseif($FilterString[$ii] -eq '(') {
            $Input = $ii + 1
            $Result = BuildFilterObject -FilterString $FilterString -OpenPos $Input
            $Filter[$Attribute.trim()] = $Result[0]
            $Attribute = ''
            $ii = $Result[1]
        } elseif($FilterString[$ii] -eq ')') {
            if($Attribute) {    # prevent empty entry when double ))
                $Filter[$Attribute.trim()] = ''
                $Attribute = ''
            }
            $ClosePos = $ii
            break
        } else {
            $Attribute = $Attribute + $FilterString[$ii]
        }
    }
    if($Attribute) {    # get last attribute
        $Filter[$Attribute.trim()] = ''
    }

    return $Filter, $ClosePos

}

function FilterResponseObject {
    <#
        Filter the data according to the given filter object. If a property on the response object does not 
        exist on the filter object, remove it. Recursively drill down into nested filter objects.
    #>

    param([pscustomobject] $Data, [hashtable] $Filter)

    foreach($JsonObject in $Data) {
        foreach($Property in (Get-Member -InputObject $JsonObject -MemberType 'NoteProperty')) {
            if( !$Filter.Contains($Property.Name) ) {
                $JsonObject.PsObject.Members.Remove($Property.Name)
            } elseif($Filter[$Property.Name]) {
                $JsonObject.($Property.Name) = FilterResponseObject -Data $JsonObject.($Property.Name) -Filter $Filter[$Property.Name]
            }
        }
    }

    return $Data
}