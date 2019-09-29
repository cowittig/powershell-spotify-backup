function Set-SpotifyAccessTokens {
    param (
        [string]$clientId,
        [string]$redirectUri
    )

    Add-Type -AssemblyName System.Web
    $redirectUri = [System.Web.HttpUtility]::UrlEncode($redirectUri)
    $responseType = 'code'
    $scope = 'playlist-read-private'
    $requestUri = "https://accounts.spotify.com/authorize?client_id=$clientId&response_type=$responseType&redirect_uri=$redirectUri&scope=$scope"


    Start-Process $requestUri
    $authCode = Read-Host "Enter the authorization code: "
    Write-Host "Authorization Code: $authCode"
}