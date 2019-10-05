function Set-SpotifyAccessTokens {
    param (
        [string] $ClientId,
        [string] $ClientSecret,
        [string] $RedirectUri
    )
    $DateFormatString = "yyyy-MM-dd HH-mm-ss"

    Add-Type -AssemblyName System.Web
    $RedirectUri = [System.Web.HttpUtility]::UrlEncode($RedirectUri)
    $ResponseType = 'code'
    $Scope = 'playlist-read-private'
    $RequestUri = "https://accounts.spotify.com/authorize?client_id=$ClientId&response_type=$ResponseType" +
                  "&redirect_uri=$RedirectUri&scope=$Scope"

    Start-Process $RequestUri
    $AuthCode = Read-Host "Enter the authorization code"
    
    $AccessRequestParams = @{
        Uri = 'https://accounts.spotify.com/api/token'
        Method = 'POST'
        ContentType = 'application/x-www-form-urlencoded' 
        Body = @{
            grant_type='authorization_code';
            code=$AuthCode;
            # redirect_uri must be decoded here!
            redirect_uri=[System.Web.HttpUtility]::UrlDecode($RedirectUri);
            client_id=$ClientId;
            client_secret=$ClientSecret
         }
    }
    $AccessResponse = Invoke-WebRequest @AccessRequestParams | ConvertFrom-Json

    $AccessToken = $AccessResponse.access_token
    $RefreshToken = $AccessResponse.refresh_token

    $ExpirationDate = ((Get-Date).AddSeconds(3480)).ToString($DateFormatString)

    @{
        client_id=$ClientId;
        client_secret=$ClientSecret;
        access_token= $AccessToken;
        refresh_token=$RefreshToken;
        expiration_date=$ExpirationDate
    } | ConvertTo-Json | Out-File settings.json

}