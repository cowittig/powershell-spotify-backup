function Get-SpotifyUserPlaylists {
    param (
        [switch] $FullFile,
        [switch] $SplitFile,
        [string] $OutDir = '.\'
    )

    if( -not $FullFile -and -not $SplitFile ) {
        Write-Host "Use -FullFile for a single file or -SplitFile for one file per playlists. You can also use both."
        return
    }

    if( -not (Test-Path $OutDir) ) {
        mkdir $OutDir | Out-Null
    }

    $Token = Get-SpotifyValidToken
    
    $UserResponse = Invoke-WebRequest -Uri "https://api.spotify.com/v1/me" -Method GET -Headers @{Authorization="Bearer $Token"} | ConvertFrom-Json
    $UserId = $UserResponse.Id

    Invoke-WebRequest -Uri "https://api.spotify.com/v1/users/$UserId/playlists?limit=50" -Method GET -Headers @{Authorization="Bearer $Token"} -OutFile .\tmp.txt
    $PlaylistsResponse = Get-Content ".\tmp.txt" -Encoding UTF8 -Raw | ConvertFrom-Json
    $PlaylistData = $PlaylistsResponse.Items

    while( $PlaylistsResponse.Next ) {
        Invoke-WebRequest -Uri $PlaylistsResponse.Next -Method GET -Headers @{Authorization="Bearer $Token"} -OutFile .\tmp.txt
        $PlaylistsResponse = Get-Content ".\tmp.txt" -Encoding UTF8 -Raw | ConvertFrom-Json
        $PlaylistData += $PlaylistsResponse.Items
    }
    
    $Playlists = [pscustomobject]@{
        playlists=@()
    }
    $PlaylistData | ForEach-Object -Process {
        Invoke-WebRequest -Uri "https://api.spotify.com/v1/playlists/$($_.id)/tracks?fields=next,items(track(name,uri,album(name,uri),artists))" -Method GET -Headers @{Authorization="Bearer $Token"} -OutFile .\tmp.txt
        $TracksResponse = Get-Content ".\tmp.txt" -Encoding UTF8 -Raw | ConvertFrom-Json
        $TrackData = $TracksResponse.Items

        while( $TracksResponse.Next ) {
            $TracksResponse = Invoke-WebRequest -Uri $TracksResponse.Next -Method GET -Headers @{Authorization="Bearer $Token"} | ConvertFrom-Json
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

    if( $FullFile ) {
        $OutFilePath = (Join-Path -Path $OutDir -ChildPath playlist-backup.json)
        $Playlists | ConvertTo-Json -Depth 10 -Compress | Out-File $OutFilePath
    }

    Remove-Item ".\tmp.txt" -Force
}