# powershell-spotify-backup

Backup your Spotify Playlists, Saved Albums and Saved Tracks as JSON files using Powershell.

## Setup
Create an App on the Spotify Developer website. You have to setup a Redirect URI. During authentification Spotify will redirect and send an authentification code to this URI. The code then has to be manually provide to the Powershell script (see below). You can use  https://cowittig.github.io/powershell-spotify-backup/ for the Redirect URI, the page will display the code if authentification was successful.

Import the module into powershell:
```
Import-Module -Name <path-to-module-dir>\powershell-spotify-backup
```

Set up the authentification by running the Set-SpotifyAccessTokens function with client id, client secret and redirect URI from your Spotify App. This needs to be done only once, the script will afterwards automatically refresh the authentification if necessary.
```
Set-SpotifyAccessTokens -ClientId xxx -ClientSecret xxx -RedirectUri xxx
```

This will open a Spotify Authorization dialog in your browser. After you have authorized the App, Spotify will send an authorization code to the provided Redirect URI. Paste the code into the Powershell prompt:
```
Enter the authorization code:
```

## Usage
### Commands
#### Backup-SpotifyUserPlaylists
Run Backup-SpotifyUserPlaylists to backup your playlists. 
```
Backup-SpotifyUserPlaylists
```

You can optionally specify an output directory, the default output directory is the module directory.
```
Backup-SpotifyUserPlaylists -OutDir C:\spotify-backup\
```

You can optionally specify whether you want a single file for all playlist data, one playlist per file or both using the `-Mode` parameter. Possible values are `'single'`, `'split'`, `'single-split'`. Default value is `'single'`. For example: 
```
Backup-SpotifyUserPlaylists -Mode 'split' -OutDir C:\spotify-backup\
```

#### Backup-SpotifyUserAlbums
Run Backup-SpotifyUserAlbums to backup your saved albums.
```
Backup-SpotifyUserAlbums
```

You can optionally specify an output directory, the default output directory is the module directory.
```
Backup-SpotifyUserAlbums -OutDir C:\spotify-backup\
```

#### Backup-SpotifyUserSongs
Run Backup-SpotifyUserSongs to backup your saved tracks.
```
Backup-SpotifyUserSongs
```

You can optionally specify an output directory, the default output directory is the module directory.
```
Backup-SpotifyUserSongs -OutDir C:\spotify-backup\
```

### Caching
Downloaded resources will be cached in the module directory. On future runs only changed data (e.g. changed playlists) will be downloaded. Unchanged data will be copied from the cache.

### Filtering
Each backup command supports a filter parameter which specifies which attributes will be stored on disk: 
```
Backup-SpotifyUserSongs -OutDir C:\spotify-backups\ -Filter 'track(artists, name, uri)'
```
To drill down into nested objects use the notation: 'nested_object(attribute, attribute)'. For no filtering use: '-Filter \*'.

For a list of attributes you can filter, check the respective API endpoints: https://developer.spotify.com/documentation/web-api/reference/playlists/get-playlist/ (playlists), https://developer.spotify.com/documentation/web-api/reference/library/get-users-saved-albums/ (saved albums), https://developer.spotify.com/documentation/web-api/reference/library/get-users-saved-tracks/ (saved songs).

Default values are:
```
Backup-SpotifyUserPlaylists    added_at, track(album(name,uri), artists(name,uri), name, uri)
Backup-SpotifyUserAlbums       added_at, album(artists(name, uri), name, release_date, uri)
Backup-SpotifyUserSongs        added_at, track(artists(name,uri), name, uri)
```

### Informational Output

If you want informational output during execution (e.g. what playlist is currently downloaded), add the `-InformationAction` flag:
```
Backup-SpotifyUserPlaylists -Mode 'split' -OutDir C:\spotify-backup\ -InformationAction:Continue
```

If you want information about whether a cached resource is used or not, add the `-Verbose` flag:
```
Backup-SpotifyUserPlaylists -Mode 'split' -OutDir C:\spotify-backup\ -Verbose
```
