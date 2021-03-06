@{
    ModuleVersion = '1.1.0'
    GUID = '9f4dfd05-124b-4665-a70f-236ec778bb08'
    Author = 'Constantin Wittig'
    Description = 'Backup your Spotify playlists, albums and songs in JSON format.'
	PowerShellVersion = '6.0'
    NestedModules = 
        '.\functions\Set-SpotifyAccessTokens.ps1',
        '.\functions\Get-SpotifyValidToken.ps1',
        '.\functions\Get-SpotifyData.ps1',
        '.\functions\Filter-SpotifyAPIResponse.ps1',
        '.\functions\Backup-SpotifyUserPlaylists.ps1',
        '.\functions\Backup-SpotifyUserAlbums.ps1',
        '.\functions\Backup-SpotifyUserSongs.ps1'
    FunctionsToExport =
        'Set-SpotifyAccessTokens',
        'Backup-SpotifyUserPlaylists',
        'Backup-SpotifyUserAlbums',
        'Backup-SpotifyUserSongs'
}