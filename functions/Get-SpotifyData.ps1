function Get-SpotifyData {
    <#
        .SYNOPSIS
            Send a Request to the Spotify API.

        .DESCRIPTION
            Send a Request to the Spotify API. Data will be cached upon first request and on future requests the
            cached version will be used, if it hasn't changed.

        .PARAMETER RequestParams
            The request data to send to the Spotify API.

        .INPUTS
    	    None. You cannot pipe input to Get-SpotifyData.

        .OUTPUTS
            A hashtable containing the data and next resource uri.
    #>

    [CmdLetBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [hashtable] $RequestParams
    )

    $ModuleBasePath = $MyInvocation.MyCommand.Module.ModuleBase

    $CacheDir = (Join-Path -Path $ModuleBasePath -ChildPath 'cache')
    if( -not (Test-Path $CacheDir) ) {
        mkdir $CacheDir | Out-Null        # do not pollute output with mkdir output
        Write-Verbose "Created cache directory $CacheDir"
    }

    $CacheIndexPath = (Join-Path -Path $CacheDir -ChildPath 'index.json')
    $Cache = @()
    if( Test-Path $CacheIndexPath ) {
        $Cache = Get-Content $CacheIndexPath | ConvertFrom-Json
    }

    # check if resource is cached
    $ETag = ''
    $nextUri = ''
    foreach( $Entry in $Cache ){
        if( $Entry.resource -eq $RequestParams.Uri ){
            $ETag = $Entry.etag
            $nextUri = $Entry.next
            break
        }
    }

    if( $ETag ) {
        # ETag has the format: "hash"
        # drop both ", so that file name is file system compatible
        $TrimmedETag = $ETag.Substring(1, $ETag.length - 2)

        $RequestParams.Headers['If-None-Match'] = $ETag

        try {
            $Response = Invoke-WebRequest @RequestParams
            $StatusCode = $Response.StatusCode
        } catch {
            # if web request was successful check if we can use the cached resource, otherwise forward exception
            if( $_.Exception.Response.StatusCode.value__ -eq 304 ) {
                $StatusCode = 304
            } else {
                throw
            }
        }

        # StatusCode 304 indicates an unchanged resource -> use cache
        if( $StatusCode -eq 304 ) {
            $entryFile = (Join-Path -Path $CacheDir -ChildPath "$TrimmedETag.json")
            $data = Get-Content $entryFile | ConvertFrom-Json
            Write-Verbose "Use cache entry ($($RequestParams.Uri), $ETag)"
        } else {
            # data has changed -> update cache index, put new file into cache and remove old file
            Write-Verbose "Update cache entry ($($RequestParams.Uri), $ETag)"
            $ResponseData = ($Response.Content | ConvertFrom-Json)
            $data = $ResponseData.Items
            $nextUri = $ResponseData.Next

            $UpdatedETag = $Response.Headers['ETag'][0]   # returns string array with 1 element -> only need the element
            foreach( $Entry in $Cache ){
                if( $Entry.resource -eq $RequestParams.Uri ){
                    $Entry.etag = $UpdatedETag
                    $Entry.next = $nextUri
                    break
                }
            }
            # ETag has the format: "hash"
            # drop both ", so that file name is file system compatible
            $TrimmedUpdatedETag = $UpdatedETag.Substring(1, $UpdatedETag.length - 2)
            $oldEntryFile = (Join-Path -Path $CacheDir -ChildPath "$TrimmedETag.json")
            $newEntryFile = (Join-Path -Path $CacheDir -ChildPath "$TrimmedUpdatedETag.json")
            Remove-Item -Path $oldEntryFile
            $data | ConvertTo-Json -Depth 10 -Compress | Out-File $newEntryFile

            ConvertTo-Json -InputObject $Cache | Out-File $CacheIndexPath

            Write-Verbose "Update cache entry ($($RequestParams.Uri), $UpdatedETag)"

        }
    } else {
        Write-Verbose "No cache entry for resource: $($RequestParams.Uri)"
        
        $Response = Invoke-WebRequest @RequestParams
        $ETag = $Response.Headers['ETag'][0]      # returns a string array with one element -> only need the element
        $ResponseData = ($Response.Content | ConvertFrom-Json)
        $data = $ResponseData.Items
        $nextUri = $ResponseData.Next
        
        # if the response has an ETag create a cache entry
        if( $Response.Headers['ETag'] ) {
            $NewCacheEntry += @{
                resource = $RequestParams.Uri
                etag = $ETag
                next = $nextUri
            }
            $Cache += $NewCacheEntry

            # ETag has the format: "hash"
            # drop both ", so that file name is file system compatible
            $fileName = $ETag.Substring(1, ($ETag.length - 2))

            $newEntryFile = (Join-Path -Path $CacheDir -ChildPath "$fileName.json")
            $data | ConvertTo-Json -Depth 10 -Compress | Out-File $newEntryFile

            ConvertTo-Json -InputObject $Cache | Out-File $CacheIndexPath

            Write-Verbose "Created cache entry ($($RequestParams.Uri), $ETag)"
        } else {
            Write-Verbose "No ETag for resource: $($RequestParams.Uri)"
        }

    }

    $returnVal = @{
        Items = $data
        Next = $nextUri
    }
    $returnVal
}