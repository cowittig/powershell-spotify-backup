function Get-SpotifyValidToken {
    param ()
    $DateFormatString = "yyyy-MM-dd HH-mm-ss"
    
    $Settings = Get-Content .\settings.json | ConvertFrom-Json
    $ExpirationDate = [datetime]::ParseExact($Settings.expiration_date, $DateFormatString, $null)

    if( $ExpirationDate -lt (Get-Date) ) {
        $AccessRequestUri = 'https://accounts.spotify.com/api/token'
        $AccessRequestMethod = 'POST'
        $AccessRequestBody = @{
            grant_type='refresh_token';
            refresh_token=$Settings.refresh_token;
            client_id=$Settings.client_id;
            client_secret=$Settings.client_secret
        }
        $AccessResponse = Invoke-WebRequest -Uri $AccessRequestUri -Method $AccessRequestMethod -Body $AccessRequestBody | ConvertFrom-Json
        $AccessToken = $AccessResponse.access_token

        $Settings.access_token = $AccessToken
        $Settings.expiration_date = ((Get-Date).AddSeconds(3480)).ToString($DateFormatString)

        $Settings | ConvertTo-Json | Out-File settings.json
    }

    return $Settings.access_token
}