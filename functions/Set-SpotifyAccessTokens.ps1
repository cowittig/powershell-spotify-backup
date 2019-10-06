function Set-SpotifyAccessTokens {
    <#
        .SYNOPSIS
            Initializes the access tokens for the Spotify API.

        .DESCRIPTION
            Initializes the access tokens for the Spotify API. During the AuthCode request Spotify will prompt
            the user to allow the App access to playlist and user profile data. This will then redirect to the
            specified -RedirectUri. Spotify will append the authorization code to the redirected uri. Paste the
            code into Powershell. The script will then get the access tokens from Spotify and store them in
            a settings file for future use.

        .PARAMETER ClientId
            The client id you specified for the App in Spotify.

        .PARAMETER ClientSecret
            The client secret you specified for the App in Spotify.

        .PARAMETER RedirectURI
            The redirect uri you specified for the App in Spotify.

        .INPUTS
            None. You cannot pipe objects to Set-SpotifyAccessTokens.

        .OUTPUTS
            A settings file in the script root directory containing the spotify access data.

        .EXAMPLE
            PS> Set-SpotifyAccessTokens -ClientId xxx -ClientSecret xxx -RedirectUri http://example.com

        .Notes

    #>

    [CmdLetBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $ClientId,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $ClientSecret,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
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