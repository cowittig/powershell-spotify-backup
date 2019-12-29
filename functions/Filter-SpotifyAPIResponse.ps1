function Filter-SpotifyAPIResponse {
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

#$FilterString = 'added_at, album(artists(name, uri), name, release_date, uri)'

#if($FilterString) {
#    $Filter = (BuildFilterObject -FilterString $FilterString -OpenPos 0)[0]
#    $Js =  Get-Content 'C:\Users\Constantin\Documents\Git Repos\powershell-spotify-backup\sample.json' | ConvertFrom-Json
#    FilterJSON -Json $Js -Filter $Filter | ConvertTo-Json
#} else {
#    Get-Content 'C:\Users\Constantin\Documents\Git Repos\powershell-spotify-backup\sample.json' | ConvertFrom-Json
#}