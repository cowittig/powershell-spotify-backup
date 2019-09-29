function Get-SpotifyUserPlaylists {
    param ()

    $token = Get-SpotifyValidToken
    
    $userResponse = Invoke-WebRequest -Uri "https://api.spotify.com/v1/me" -Method GET -Headers @{Authorization="Bearer $token"} | ConvertFrom-Json
    $userId = $userResponse.id

    $playlistsResponse = Invoke-WebRequest -Uri "https://api.spotify.com/v1/users/$userId/playlists?limit=50" -Method GET -Headers @{Authorization="Bearer $token"} | ConvertFrom-Json
    $playlistData = $playlistsResponse.items

    while( $playlistsResponse.next ) {
        $playlistsResponse = Invoke-WebRequest -Uri $playlistsResponse.next -Method GET -Headers @{Authorization="Bearer $token"} | ConvertFrom-Json
        $playlistData = $playlistData + $playlistsResponse.items
    }
    
    $playlists = @()
    $playlistData | ForEach-Object -Process {
        $tracksResponse = Invoke-WebRequest -Uri "https://api.spotify.com/v1/playlists/$($_.id)/tracks?fields=next,items(track(name,uri,track_number,album(name,uri),artists))" -Method GET -Headers @{Authorization="Bearer $token"} | ConvertFrom-Json
        $trackData = $tracksResponse.items
        while( $tracksResponse.next ) {
            $tracksResponse = Invoke-WebRequest -Uri $tracksResponse.next -Method GET -Headers @{Authorization="Bearer $token"} | ConvertFrom-Json
            $trackData = $trackData + $tracksResponse.items
        }
        $trackData | ForEach-Object -Process {
            $artistsSmall = @();
            $_.track.artists | ForEach-Object -Process { 
                $artistsSmall = $artistsSmall + @(@{name=$_.name; uri=$_.uri})
            }
            $_.track.artists = $artistsSmall
        }

        $playlists = $playlists + @(@{ name=$_.name; uri=$_.uri; trackCount=$_.tracks.total; tracks= @() + $trackData})
    }    

    $playlists | ConvertTo-Json -Depth 10 | Out-File playlists.json
}