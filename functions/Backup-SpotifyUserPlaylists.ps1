function Backup-SpotifyUserPlaylists {
    <#
        .SYNOPSIS
            Exports your playlists from Spotify. in JSON format to either a single file, one file per playlist
            or both.

        .DESCRIPTION
            Exports your playlists from Spotify in JSON format. Performs a WebRequest to retrieve the
            Spotify User Profile in order to extract the user id. Then the playlists of that user are requested
            and afterwards the tracks for each playlist. The result is then stored in either a single file, one
            file per playlist or both. A cached version will be used if the list of tracks has not changed.

        .PARAMETER Mode
            Specifies whether the output is a single file ('single'), one file per playlist ('split')
            or both ('single-split'). Default is 'single'.

        .PARAMETER Filter
            Filter the attributes that will be stored on disk. Only the attributes in the filter string will be
            stored. Check the API reference for playlists at https://developer.spotify.com/documentation/web-api/reference/playlists/get-playlist/
            for a list of returned attributes. You can drill down into nested objects using
            the notation: nested_object(attribute, attribute). 
            For no filtering, use '-Filter *'
            Default filter is: added_at, track(album(name,uri), artists(name,uri), name, uri)

        .PARAMETER OutDir
            Output directory. Default is the module root directory ($MyInvocation.MyCommand.Module.ModuleBase)

        .INPUTS
    	    None. You cannot pipe input to Backup-SpotifyUserPlaylists.

        .OUTPUTS
            Depending on the -Mode parameter one or multiple JSON files containing playlist data are stored
            in the specified output directory.

        .EXAMPLE
            PS> Backup-SpotifyUserPlaylists -Mode single -OutDir C:\spotify-backups\

        .EXAMPLE
            PS> Backup-SpotifyUserPlaylists -Mode split -OutDir C:\spotify-backups\ -Filter 'track(album, artists), name, uri'
    #>

    [CmdLetBinding()]
    param (
        [ValidateSet('single', 'split', 'single-split')]
        [string] $Mode = 'single',

        [string] $Filter = 'added_at, track(album(name,uri), artists(name,uri), name, uri)',
        [string] $OutDir = $MyInvocation.MyCommand.Module.ModuleBase
    )


    if($Mode -eq 'single' -or $Mode -eq 'single-split') {
        $SingleFile = $True
    }

    if($Mode -eq 'split' -or $Mode -eq 'single-split') {
        $SplitFile = $True
    }

    if( -not (Test-Path $OutDir) ) {
        mkdir $OutDir | Out-Null        # do not pollute output with mkdir output
        Write-Information "Created output directory $OutDir"
    }

    $Token = Get-SpotifyValidToken

    Write-Information 'Requesting user profile.'
    $UserRequestParams = @{
        Uri = 'https://api.spotify.com/v1/me'
        Method = 'GET'
        Headers = @{ Authorization = "Bearer $Token" }
    }
    $UserResponse = Invoke-WebRequest @UserRequestParams | ConvertFrom-Json
    $UserId = $UserResponse.Id
    Write-Information 'Spotify User ID received.'

    Write-Information 'Requesting user playlists.'
    $PlaylistsRequestParams = @{
        Uri = "https://api.spotify.com/v1/users/$UserId/playlists?offset=0&limit=50"
        Method = 'GET'
        Headers = @{ Authorization = "Bearer $Token" }
    }
    $Result = Get-SpotifyData -RequestParams $PlaylistsRequestParams -Filter '*'
    $PlaylistData = $Result.Items

    while( $Result.Next ) {
        Write-Information 'Requesting more user playlists.'
        $PlaylistsRequestParams = @{
            Uri = $Result.Next
            Method = 'GET'
            Headers = @{ Authorization = "Bearer $Token" }
        }
        $Result = Get-SpotifyData -RequestParams $PlaylistsRequestParams -Filter '*'
        $PlaylistData += $Result.Items
    }
    
    $Playlists = @()
    foreach( $pl in $PlaylistData ) {
        $TrackData = $null

        Write-Information "Requesting tracks for playlist $($pl.name)."
        $TracksRequestParams = @{
            Uri = "https://api.spotify.com/v1/playlists/$($pl.id)/tracks?offset=0&limit=100&" + 
                  "fields=next,items($Filter)"
            Method = 'GET'
            Headers = @{ Authorization = "Bearer $Token" }
        }
        $Result = Get-SpotifyData -RequestParams $TracksRequestParams -Filter $Filter
        $TrackData += $Result.Items

        while( $Result.Next ) {
            Write-Information "Requesting more tracks for playlist $($pl.name)."
            $TracksRequestParams = @{
                Uri = $Result.Next
                Method = 'GET'
                Headers = @{ Authorization = "Bearer $Token" }
            }
            $Result = Get-SpotifyData -RequestParams $TracksRequestParams -Filter $Filter
            $TrackData += $Result.Items
        }

        # artists data returned from Spotify contains many undesired fields which cannot be filtered at request
        # only need artist name and uri
        foreach( $t in $TrackData ) {
            $ArtistsSmall = @();
            if( $t.Track.Artists ) {
                foreach( $a in $t.Track.Artists ) { 
                    $ArtistsSmall += @(@{name=$a.Name; uri=$a.Uri})
                }
                $t.Track.Artists = $ArtistsSmall
            }
        }

        # use pscustomobject to retain the property order when writing to JSON
        $CurrPlaylist = [pscustomobject]@{
            name=$pl.Name;
            uri=$pl.Uri;
            trackCount=$pl.Tracks.Total;
            tracks = $TrackData
        }
        $Playlists += $CurrPlaylist

        if( $SplitFile ) {
            $OutFilePath = (Join-Path -Path $OutDir -ChildPath "$($pl.Id).json")
            ConvertTo-Json -InputObject $CurrPlaylist -Depth 10 -Compress | Out-File $OutFilePath
            Write-Information "Created file for playlist $($pl.name)."
        }
    }  
    
    if( $SplitFile ) {
        $OutFilePath = (Join-Path -Path $OutDir -ChildPath playlists.index)
        $PlaylistData | ForEach-Object { "id: $($_.Id)    name: $($_.Name)" } | Out-File $OutFilePath
        Write-Information "Created index file for playlist data."
    }

    if( $SingleFile ) {
        $OutFilePath = (Join-Path -Path $OutDir -ChildPath playlist-backup.json)
        ConvertTo-Json -InputObject $Playlists -Depth 10 -Compress | Out-File $OutFilePath
        Write-Information "Created backup file."
    }

}