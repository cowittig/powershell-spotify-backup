@{
    ModuleVersion = '1.0.0'
    GUID = '9f4dfd05-124b-4665-a70f-236ec778bb08'
    Author = 'Constantin Wittig'
    Description = 'Backup your Spotify playlists to a single JSON file or one file per playlist.'
	PowerShellVersion = '5.1'
    NestedModules = 
        '.\functions\Set-SpotifyAccessTokens.ps1',
        '.\functions\Get-SpotifyValidToken.ps1',
        '.\functions\Backup-SpotifyUserPlaylists.ps1'
    FunctionsToExport =
        'Set-SpotifyAccessTokens',
        'Backup-SpotifyUserPlaylists'
}