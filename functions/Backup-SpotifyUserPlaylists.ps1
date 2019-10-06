function Backup-SpotifyUserPlaylists {
    <#
        .SYNOPSIS
            Exports your playlists from Spotify. in JSON format to either a single file, one file per playlist
            or both.

        .DESCRIPTION
            Exports your playlists from Spotify in JSON format. Performs a WebRequest to retrieve the
            Spotify User Profile in order to extract the user id. Then the playlists of that user are requested
            and afterwards the tracks for each playlist. The result is then stored in either a single file, one
            file per playlist or both.

        .PARAMETER Mode
            Specifies whether the output is a single file ('single'), one file per playlist ('split')
            or both ('single-split'). Default is 'single'.

        .PARAMETER OutDir
            Output directory. Default is the script root directory ($PSScriptRoot)

        .INPUTS
    	    None. You cannot pipe input to Backup-SpotifyUserPlaylists.

        .OUTPUTS
            Depending on the -Mode parameter one or multiple JSON files containing playlist data are stored
            in the specified output directory.

        .EXAMPLE
            PS> Backup-SpotifyUserPlaylists -Mode single -OutDir C:\spotify-backups\

        .Notes
            Will create a temporary file in the script root directory. Powershell interprets responses from
            Spotify Web API as encoded in ISO-8859-1, however Spotify uses UTF-8. As a workaround, output from 
            Invoke-WebRequest is directly stored in a temp file and then explicitly loaded with 
            UTF-8 enconfing. The temp file is removed at the end of the script.
    #>

    [CmdLetBinding()]
    param (
        [ValidateSet('single', 'split', 'single-split')]
        [string] $Mode = 'single',

        [string] $OutDir = $PSScriptRoot
    )

    if($Mode -eq 'single' -or $Mode -eq 'single-split') {
        $SingleFile = $True
    }

    if($Mode -eq 'split' -or $Mode -eq 'single-split') {
        $SplitFile = $True
    }

    if( -not (Test-Path $OutDir) ) {
        mkdir $OutDir | Out-Null        # do not pollute output with mkdir output
    }

    $TmpFilePath = (Join-Path -Path $PSScriptRoot -ChildPath 'tmp.txt')

    $Token = Get-SpotifyValidToken
    
    $UserRequestParams = @{
        Uri = 'https://api.spotify.com/v1/me'
        Method = 'GET'
        Headers = @{ Authorization = "Bearer $Token" }
    }
    $UserResponse = Invoke-WebRequest @UserRequestParams | ConvertFrom-Json
    $UserId = $UserResponse.Id

    $PlaylistsRequestParams = @{
        Uri = "https://api.spotify.com/v1/users/$UserId/playlists?limit=50"
        Method = 'GET'
        Headers = @{ Authorization = "Bearer $Token" }
        OutFile = $TmpFilePath
    }
    Invoke-WebRequest @PlaylistsRequestParams
    $PlaylistsResponse = Get-Content $TmpFilePath -Encoding UTF8 -Raw | ConvertFrom-Json
    $PlaylistData = $PlaylistsResponse.Items

    while( $PlaylistsResponse.Next ) {
        $PlaylistsRequestParams = @{
            Uri = $PlaylistsResponse.Next
            Method = 'GET'
            Headers = @{ Authorization = "Bearer $Token" }
            OutFile = $TmpFilePath
        }
        Invoke-WebRequest @PlaylistsRequestParams
        $PlaylistsResponse = Get-Content $TmpFilePath -Encoding UTF8 -Raw | ConvertFrom-Json
        $PlaylistData += $PlaylistsResponse.Items
    }
    
    $Playlists = [pscustomobject]@{
        playlists=@()
    }
    $PlaylistData | ForEach-Object -Process {
        $TracksRequestParams = @{
            Uri = "https://api.spotify.com/v1/playlists/$($_.id)/tracks?fields=next," + 
                  "items(track(name,uri,album(name,uri),artists))"
            Method = 'GET'
            Headers = @{ Authorization = "Bearer $Token" }
            OutFile = $TmpFilePath
        }
        Invoke-WebRequest @TracksRequestParams
        $TracksResponse = Get-Content $TmpFilePath -Encoding UTF8 -Raw | ConvertFrom-Json
        $TrackData = $TracksResponse.Items

        while( $TracksResponse.Next ) {
            $TracksRequestParams = @{
                Uri = $TracksResponse.Next
                Method = 'GET'
                Headers = @{ Authorization = "Bearer $Token" }
            }
            $TracksResponse = Invoke-WebRequest @TracksRequestParams | ConvertFrom-Json
            $TrackData += $TracksResponse.Items
        }

        # artists data returned from Spotify contains many undesired fields which cannot be filtered at request
        # only need artist name and uri
        $TrackData | ForEach-Object -Process {
            $ArtistsSmall = @();
            if( $_.Track.Artists ) {
                $_.Track.Artists | ForEach-Object -Process { 
                    $ArtistsSmall += @(@{name=$_.Name; uri=$_.Uri})
                }
                $_.Track.Artists = $ArtistsSmall
            }
        }

        $CurrPlaylist = [pscustomobject]@{
            name=$_.Name;
            uri=$_.Uri;
            trackCount=$_.Tracks.Total;
            tracks = $TrackData
        }
        $Playlists.Playlists += $CurrPlaylist

        if( $SplitFile ) {
            $OutFilePath = (Join-Path -Path $OutDir -ChildPath "$($_.Id).json")
            $CurrPlaylist | ConvertTo-Json -Depth 10 -Compress | Out-File $OutFilePath
        }
    }  
    
    if( $SplitFile ) {
        $OutFilePath = (Join-Path -Path $OutDir -ChildPath playlists.index)
        $PlaylistData | ForEach-Object { "id: $($_.Id)    name: $($_.Name)" } | Out-File $OutFilePath
    }

    if( $SingleFile ) {
        $OutFilePath = (Join-Path -Path $OutDir -ChildPath playlist-backup.json)
        $Playlists | ConvertTo-Json -Depth 10 -Compress | Out-File $OutFilePath
    }

    Remove-Item $TmpFilePath -Force
}