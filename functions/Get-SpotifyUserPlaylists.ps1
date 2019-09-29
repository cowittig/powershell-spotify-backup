function Get-SpotifyUserPlaylists {
    param ()
    
    $token = Get-SpotifyValidToken
    Invoke-RestMethod -Uri "https://api.spotify.com/v1/users/buddhaaaa/playlists" -Method GET -Headers @{Authorization="Bearer $token"}

}