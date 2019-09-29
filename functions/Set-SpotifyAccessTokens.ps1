function Set-SpotifyAccessTokens {
    param (
        [string]$clientId,
        [string]$clientSecret,
        [string]$redirectUri
    )
    $dateFormatString = "yyyy-MM-dd HH-mm-ss"

    Add-Type -AssemblyName System.Web
    $redirectUri = [System.Web.HttpUtility]::UrlEncode($redirectUri)
    $responseType = 'code'
    $scope = 'playlist-read-private'
    $requestUri = "https://accounts.spotify.com/authorize?client_id=$clientId&response_type=$responseType&redirect_uri=$redirectUri&scope=$scope"

    Start-Process $requestUri
    $authCode = Read-Host "Enter the authorization code"
    
    $accessRequestUri = 'https://accounts.spotify.com/api/token'
    $accessRequestMethod = 'POST'
    $accessRequestContentType = 'application/x-www-form-urlencoded'
    $accessRequestBody = @{
        grant_type='authorization_code';
        code=$authCode;
        # redirect_uri must be decoded here!
        redirect_uri=[System.Web.HttpUtility]::UrlDecode($redirectUri);
        client_id=$clientId;
        client_secret=$clientSecret
    }
    $accessResponse = Invoke-WebRequest -Uri $accessRequestUri -Method $accessRequestMethod -ContentType $accessRequestContentType -Body $accessRequestBody | ConvertFrom-Json

    $accessToken = $accessResponse.access_token
    $refreshToken = $accessResponse.refresh_token

    $expirationDate = ((Get-Date).AddSeconds(3480)).ToString($dateFormatString)

    @{
        client_id=$clientId;
        client_secret=$clientSecret;
        access_token=$accessToken;
        refresh_token=$refreshToken;
        expiration_date=$expirationDate
    } | ConvertTo-Json | Out-File settings.json

}