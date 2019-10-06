@{
    ModuleVersion = '0.1'
    GUID = '9f4dfd05-124b-4665-a70f-236ec778bb08'
    Author = 'Constantin Wittig'
    Description = 'Backup your Spotify playlists to a single JSON file or multiple 
        JSON files per playlist.'
    NestedModules = 
        '.\functions\Set-SpotifyAccessTokens.ps1',
        '.\functions\Get-SpotifyValidToken.ps1',
        '.\functions\Backup-SpotifyUserPlaylists.ps1'
    FunctionsToExport =
        'Set-SpotifyAccessTokens',
        'Backup-SpotifyUserPlaylists'
}