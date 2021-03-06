function Set-SpotifyAccessTokens {
    <#
        .SYNOPSIS
            Initializes the access tokens for the Spotify API.

        .DESCRIPTION
            Initializes the access tokens for the Spotify API. During the AuthCode request Spotify will prompt
            the user to allow the App access to playlist, library and user profile data. This will then redirect
            to the specified -RedirectUri. Spotify will append the authorization code to the redirected uri. Paste
            the code into Powershell. The script will then get the access tokens from Spotify and store them in
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
            A settings file in the module root directory containing the spotify access data.

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
    $DateFormatString = 'yyyy-MM-dd HH-mm-ss'
    $SettingsPath = (Join-Path -Path $MyInvocation.MyCommand.Module.ModuleBase -ChildPath 'settings.json')

    Add-Type -AssemblyName System.Web
    $RedirectUriEncoded = [System.Web.HttpUtility]::UrlEncode($RedirectUri)
    $ResponseType = 'code'
    $Scope = 'playlist-read-private,user-library-read'
    $RequestUri = "https://accounts.spotify.com/authorize?client_id=$ClientId&response_type=$ResponseType" +
                  "&redirect_uri=$RedirectUriEncoded&scope=$Scope"

    Start-Process $RequestUri
    Write-Information 'Started Browser to display Spotify prompt and redirect uri.'
    $AuthCode = Read-Host 'Enter the authorization code'
    
    Write-Information 'Send request for access and refresh token.'
    $AccessRequestParams = @{
        Uri = 'https://accounts.spotify.com/api/token'
        Method = 'POST'
        ContentType = 'application/x-www-form-urlencoded' 
        Body = @{
            grant_type='authorization_code';
            code=$AuthCode;
            redirect_uri=$RedirectUri
            client_id=$ClientId;
            client_secret=$ClientSecret
         }
    }
    $AccessResponse = Invoke-WebRequest @AccessRequestParams | ConvertFrom-Json
    Write-Information 'Response received'.

    $AccessToken = $AccessResponse.access_token
    $RefreshToken = $AccessResponse.refresh_token

    $ExpirationDate = ((Get-Date).AddSeconds(3480)).ToString($DateFormatString)

    @{
        client_id=$ClientId;
        client_secret=$ClientSecret;
        access_token= $AccessToken;
        refresh_token=$RefreshToken;
        expiration_date=$ExpirationDate
    } | ConvertTo-Json | Out-File $SettingsPath

    Write-Information 'Access data written to settings file.'
}
