function Backup-SpotifyUserPlaylists {
    param (
        [ValidateSet('single', 'split', 'single-split')]
        [string] $Mode = 'single',

        [string] $OutDir = '.\'
    )

    if($Mode -eq 'single' -or $Mode -eq 'single-split') {
        $SingleFile = $True
    }

    if($Mode -eq 'split' -or $Mode -eq 'single-split') {
        $SplitFile = $True
    }

    if( -not (Test-Path $OutDir) ) {
        mkdir $OutDir | Out-Null
    }

    $Token = Get-SpotifyValidToken
    
    $UserRequestParams = @{
        Uri = "https://api.spotify.com/v1/me"
        Method = "GET"
        Headers = @{ Authorization = "Bearer $Token" }
    }
    $UserResponse = Invoke-WebRequest @UserRequestParams | ConvertFrom-Json
    $UserId = $UserResponse.Id

    $PlaylistsRequestParams = @{
        Uri = "https://api.spotify.com/v1/users/$UserId/playlists?limit=50"
        Method = "GET"
        Headers = @{ Authorization = "Bearer $Token" }
        OutFile = '.\tmp.txt'
    }
    Invoke-WebRequest @PlaylistsRequestParams
    $PlaylistsResponse = Get-Content ".\tmp.txt" -Encoding UTF8 -Raw | ConvertFrom-Json
    $PlaylistData = $PlaylistsResponse.Items

    while( $PlaylistsResponse.Next ) {
        $PlaylistsRequestParams = @{
            Uri = $PlaylistsResponse.Next
            Method = "GET"
            Headers = @{ Authorization = "Bearer $Token" }
            OutFile = '.\tmp.txt'
        }
        Invoke-WebRequest @PlaylistsRequestParams
        $PlaylistsResponse = Get-Content ".\tmp.txt" -Encoding UTF8 -Raw | ConvertFrom-Json
        $PlaylistData += $PlaylistsResponse.Items
    }
    
    $Playlists = [pscustomobject]@{
        playlists=@()
    }
    $PlaylistData | ForEach-Object -Process {
        $TracksRequestParams = @{
            Uri = "https://api.spotify.com/v1/playlists/$($_.id)/tracks?fields=next," + 
                  "items(track(name,uri,album(name,uri),artists))"
            Method = "GET"
            Headers = @{ Authorization = "Bearer $Token" }
            OutFile = '.\tmp.txt'
        }
        Invoke-WebRequest @TracksRequestParams
        $TracksResponse = Get-Content ".\tmp.txt" -Encoding UTF8 -Raw | ConvertFrom-Json
        $TrackData = $TracksResponse.Items

        while( $TracksResponse.Next ) {
            $TracksRequestParams = @{
                Uri = $TracksResponse.Next
                Method = "GET"
                Headers = @{ Authorization = "Bearer $Token" }
            }
            $TracksResponse = Invoke-WebRequest @TracksRequestParams | ConvertFrom-Json
            $TrackData += $TracksResponse.Items
        }

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

    Remove-Item ".\tmp.txt" -Force
}