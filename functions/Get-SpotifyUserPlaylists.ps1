function Get-SpotifyUserPlaylists {
    param (
        [switch] $fullFile,
        [switch] $splitFile,
        [string] $outDir = '.\'
    )

    if( -Not $fullFile -And -Not $splitFile ) {
        Write-Host "Use -FullFile for a single file or -SplitFile for one file per playlists. You can also use both."
        return
    }

    if( -Not (Test-Path $outDir) ) {
        mkdir $outDir | Out-Null
    }

    $token = Get-SpotifyValidToken
    
    $userResponse = Invoke-WebRequest -Uri "https://api.spotify.com/v1/me" -Method GET -Headers @{Authorization="Bearer $token"} | ConvertFrom-Json
    $userId = $userResponse.id

    Invoke-WebRequest -Uri "https://api.spotify.com/v1/users/$userId/playlists?limit=50" -Method GET -Headers @{Authorization="Bearer $token"} -OutFile .\tmp.txt
    $playlistsResponse = Get-Content ".\tmp.txt" -Encoding UTF8 -Raw | ConvertFrom-Json
    $playlistData = $playlistsResponse.items

    while( $playlistsResponse.next ) {
        Invoke-WebRequest -Uri $playlistsResponse.next -Method GET -Headers @{Authorization="Bearer $token"} -OutFile .\tmp.txt
        $playlistsResponse = Get-Content ".\tmp.txt" -Encoding UTF8 -Raw | ConvertFrom-Json
        $playlistData += $playlistsResponse.items
    }
    
    $playlists = [pscustomobject]@{
        playlists=@()
    }
    $playlistData | ForEach-Object -Process {
        Invoke-WebRequest -Uri "https://api.spotify.com/v1/playlists/$($_.id)/tracks?fields=next,items(track(name,uri,album(name,uri),artists))" -Method GET -Headers @{Authorization="Bearer $token"} -OutFile .\tmp.txt
        $tracksResponse = Get-Content ".\tmp.txt" -Encoding UTF8 -Raw | ConvertFrom-Json
        $trackData = $tracksResponse.items

        while( $tracksResponse.next ) {
            $tracksResponse = Invoke-WebRequest -Uri $tracksResponse.next -Method GET -Headers @{Authorization="Bearer $token"} | ConvertFrom-Json
            $trackData += $tracksResponse.items
        }

        $trackData | ForEach-Object -Process {
            $artistsSmall = @();
            if( $_.track.artists ) {
                $_.track.artists | ForEach-Object -Process { 
                    $artistsSmall += @(@{name=$_.name; uri=$_.uri})
                }
                $_.track.artists = $artistsSmall
            }
        }

        $currPlaylist = [pscustomobject]@{
            name=$_.name;
            uri=$_.uri;
            trackCount=$_.tracks.total;
            tracks = $trackData
        }
        $playlists.playlists += $currPlaylist

        if( $splitFile ) {
            $outFilePath = (Join-Path -Path $outDir -ChildPath "$($_.id).json")
            $currPlaylist | ConvertTo-Json -Depth 10 | Out-File $outFilePath
        }
    }  
    
    if( $splitFile ) {
        $outFilePath = (Join-Path -Path $outDir -ChildPath playlists.index)
        $playlistData | ForEach-Object { "id: $($_.id)    name: $($_.name)" } | Out-File $outFilePath
    }

    if( $fullFile ) {
        $outFilePath = (Join-Path -Path $outDir -ChildPath playlist-backup.json)
        $playlists | ConvertTo-Json -Depth 10 | Out-File $outFilePath
    }

    Remove-Item ".\tmp.txt" -Force
}