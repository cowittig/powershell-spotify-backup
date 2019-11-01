# powershell-spotify-backup

Backup your Spotify Playlists as JSON files using Powershell. You can store the data in a single file or one file per playlist (or both).

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

Now you can run Backup-SpotifyUserPlaylists to backup your data. 
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

If you want informational output during execution (e.g. what playlist is currently downloaded), add the `-InformationAction` flag:
```
Backup-SpotifyUserPlaylists -Mode 'split' -OutDir C:\spotify-backup\ -InformationAction:Continue
```
