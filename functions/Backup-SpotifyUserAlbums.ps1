function Backup-SpotifyUserAlbums {
    <#
        .SYNOPSIS
            Exports your favorite albums from Spotify to a JSON file.

        .DESCRIPTION
            Exports your favorite albums from Spotify to a JSON file. The albums of the user are requested and 
            the result is stored in a JSON file in the specified output directory or in the module base directory,
            if no output directory is specified.

        .PARAMETER OutDir
            Output directory. Default is the module root directory ($MyInvocation.MyCommand.Module.ModuleBase)

        .INPUTS
    	    None. You cannot pipe input to Backup-SpotifyUserAlbums.

        .OUTPUTS
            A JSON file containing the users favorite albums in the specified or default output directory.

        .EXAMPLE
            PS> Backup-SpotifyUserAlbums -OutDir C:\spotify-backups\

        .Notes
            Will create a temporary file in the module root directory. Powershell interprets responses from
            Spotify Web API as encoded in ISO-8859-1, however Spotify uses UTF-8. As a workaround, output from 
            Invoke-WebRequest is directly stored in a temp file and then explicitly loaded with 
            UTF-8 enconfing. The temp file is removed at the end of the script.
    #>

    [CmdLetBinding()]
    param (
        [string] $OutDir = $MyInvocation.MyCommand.Module.ModuleBase
    )

    if( -not (Test-Path $OutDir) ) {
        mkdir $OutDir | Out-Null        # do not pollute output with mkdir output
        Write-Information "Created output directory $OutDir"
    }

    $ModuleBasePath = $MyInvocation.MyCommand.Module.ModuleBase

    $TmpFilePath = (Join-Path -Path $ModuleBasePath -ChildPath 'tmp.txt')

    $Token = Get-SpotifyValidToken

    Write-Information 'Requesting user albums.'
    $AlbumsRequestParams = @{
        Uri = "https://api.spotify.com/v1/me/albums?limit=50"
        Method = 'GET'
        Headers = @{ Authorization = "Bearer $Token" }
        OutFile = $TmpFilePath
    }
    Invoke-WebRequest @AlbumsRequestParams
    Write-Information 'Response received.'
    $AlbumsResponse = Get-Content $TmpFilePath -Encoding UTF8 -Raw | ConvertFrom-Json
    $Albums = $AlbumsResponse.Items

    while( $AlbumsResponse.Next ) {
        Write-Information 'Requesting more user albums.'
        $AlbumsRequestParams = @{
            Uri = $AlbumsResponse.Next
            Method = 'GET'
            Headers = @{ Authorization = "Bearer $Token" }
            OutFile = $TmpFilePath
        }
        Invoke-WebRequest @AlbumsRequestParams
        Write-Information 'Response received.'
        $AlbumsResponse = Get-Content $TmpFilePath -Encoding UTF8 -Raw | ConvertFrom-Json
        $Albums += $AlbumsResponse.Items
    } 

    $OutFilePath = (Join-Path -Path $OutDir -ChildPath albums-backup.json)
    $Albums | ConvertTo-Json -Depth 10 -Compress | Out-File $OutFilePath
    Write-Information "Created albums backup file."

    Remove-Item $TmpFilePath -Force
}