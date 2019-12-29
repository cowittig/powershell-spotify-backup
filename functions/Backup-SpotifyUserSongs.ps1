function Backup-SpotifyUserSongs {
    <#
        .SYNOPSIS
            Exports your favorite tracks from Spotify to a JSON file.

        .DESCRIPTION
            Exports your favorite tracks from Spotify to a JSON file. The tracks of the user are requested and 
            the result is stored in a JSON file in the specified output directory or in the module base directory,
            if no output directory is specified. A cached version will be used if the list of tracks has not changed.

        .PARAMETER OutDir
            Output directory. Default is the module root directory ($MyInvocation.MyCommand.Module.ModuleBase)

        .INPUTS
    	    None. You cannot pipe input to Backup-SpotifyUserSongs.

        .OUTPUTS
            A JSON file containing the users favorite songs in the specified or default output directory.

        .EXAMPLE
            PS> Backup-SpotifyUserSongs -OutDir C:\spotify-backups\
    #>

    [CmdLetBinding()]
    param (
        [string] $Filter = 'added_at, track(artists(name,uri), name, uri)',
        [string] $OutDir = $MyInvocation.MyCommand.Module.ModuleBase
    )

    if( -not (Test-Path $OutDir) ) {
        mkdir $OutDir | Out-Null        # do not pollute output with mkdir output
        Write-Information "Created output directory $OutDir"
    }

    $Token = Get-SpotifyValidToken

    Write-Information 'Requesting user songs.'
    $SongsRequestParams = @{
        Uri = 'https://api.spotify.com/v1/me/tracks?offset=0&limit=50'
        Method = 'GET'
        Headers = @{ Authorization = "Bearer $Token" }
    }
    $Result = Get-SpotifyData -RequestParams $SongsRequestParams -Filter $Filter
    $Songs = $Result.Items

    while( $Result.Next ) {
        Write-Information 'Requesting more user songs.'
        $SongsRequestParams = @{
            Uri = $Result.Next
            Method = 'GET'
            Headers = @{ Authorization = "Bearer $Token" }
        }
        $Result = Get-SpotifyData -RequestParams $SongsRequestParams -Filter $Filter
        $Songs += $Result.Items
    }

    $OutFilePath = (Join-Path -Path $OutDir -ChildPath songs-backup.json)
    $Songs | ConvertTo-Json -Depth 10 -Compress | Out-File $OutFilePath
    Write-Information 'Created songs backup file.'
}