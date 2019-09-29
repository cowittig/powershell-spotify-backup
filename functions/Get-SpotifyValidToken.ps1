function Get-SpotifyValidToken {
    param ()
    $dateFormatString = "yyyy-MM-dd HH-mm-ss"
    
    $settings = Get-Content .\settings.json | ConvertFrom-Json
    $expiration_date = [DateTime]::ParseExact($settings.expiration_date, $dateFormatString, $null)

    if( $expiration_date -lt (Get-Date) ) {
        $accessRequestUri = 'https://accounts.spotify.com/api/token'
        $accessRequestMethod = 'POST'
        $accessRequestBody = @{
            grant_type='refresh_token';
            refresh_token=$settings.refresh_token;
            client_id=$settings.client_id;
            client_secret=$settings.client_secret
        }
        $accessResponse = Invoke-WebRequest -Uri $accessRequestUri -Method $accessRequestMethod -Body $accessRequestBody | ConvertFrom-Json
        $accessToken = $accessResponse.access_token

        $settings.access_token = $accessToken
        $settings.expiration_date = ((Get-Date).AddSeconds(3480)).ToString($dateFormatString)

        $settings | ConvertTo-Json | Out-File settings.json
    }

    return $settings.access_token
}