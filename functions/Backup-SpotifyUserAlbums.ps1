function Backup-SpotifyUserAlbums {
    <#
        .SYNOPSIS
            Exports your favorite albums from Spotify to a JSON file.

        .DESCRIPTION
            Exports your favorite albums from Spotify to a JSON file. The albums of the user are requested and 
            the result is stored in a JSON file in the specified output directory or in the module base directory,
            if no output directory is specified. A cached version will be used if the list of albums has not changed.

        .PARAMETER Filter
            Filter the attributes that will be stored on disk. Only the attributes in the filter string will be
            stored. Check the API reference for saved albums at https://developer.spotify.com/documentation/web-api/reference/library/get-users-saved-albums/
            for a list of returned attributes. You can drill down into nested objects using
            the notation: nested_object(attribute, attribute). 
            For no filtering, use '-Filter *'
            Default filter is: added_at, album(artists(name, uri), name, release_date, uri)

        .PARAMETER OutDir
            Output directory. Default is the module root directory ($MyInvocation.MyCommand.Module.ModuleBase)

        .INPUTS
    	    None. You cannot pipe input to Backup-SpotifyUserAlbums.

        .OUTPUTS
            A JSON file containing the users favorite albums in the specified or default output directory.

        .EXAMPLE
            PS> Backup-SpotifyUserAlbums -OutDir C:\spotify-backups\

        .EXAMPLE
            PS> Backup-SpotifyUserAlbums -OutDir C:\spotify-backups\ -Filter 'album(artists, name, uri)'
    #>

    [CmdLetBinding()]
    param (
        [string] $Filter = 'added_at, album(artists(name, uri), name, release_date, uri)',
        [string] $OutDir = $MyInvocation.MyCommand.Module.ModuleBase
    )

    if( -not (Test-Path $OutDir) ) {
        mkdir $OutDir | Out-Null        # do not pollute output with mkdir output
        Write-Information "Created output directory $OutDir"
    }

    $Token = Get-SpotifyValidToken

    Write-Information 'Requesting user albums.'
    $AlbumsRequestParams = @{
        Uri = 'https://api.spotify.com/v1/me/albums?offset=0&limit=50'
        Method = 'GET'
        Headers = @{ Authorization = "Bearer $Token" }
    }
    $Result = Get-SpotifyData -RequestParams $AlbumsRequestParams -Filter $Filter
    $Albums = $Result.Items

    while( $Result.Next ) {
        Write-Information 'Requesting more user albums.'
        $AlbumsRequestParams = @{
            Uri = $Result.Next
            Method = 'GET'
            Headers = @{ Authorization = "Bearer $Token" }
        }
        $Result = Get-SpotifyData -RequestParams $AlbumsRequestParams -Filter $Filter
        $Albums += $Result.Items
    }

    $OutFilePath = (Join-Path -Path $OutDir -ChildPath albums-backup.json)
    $Albums | ConvertTo-Json -Depth 10 -Compress | Out-File $OutFilePath
    Write-Information 'Created albums backup file.'
}