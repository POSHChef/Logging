<#
Copyright 2014 ASOS.com Limited

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
#>


<# wrapper functions to aid testability #>

function _loadType($dllPath)
{
    if (Test-Path $dllPath) {
        $assemblyBytes = [System.IO.File]::ReadAllBytes($dllPath);
        $assemblyLoaded = [System.Reflection.Assembly]::Load($assemblyBytes);
    } else {
        throw "Could not find the assembly: $dllPath"
    }
}
function _prettyPrint($json)
{
    return [JsonPrettyPrinterPlus.PrettyPrinterExtensions]::PrettyPrintJson($json)
}


<# main function #>

function Format-Json
{

    <#

    .SYNOPSIS
    Render an object as a nicely formatted JSON string.

    .DESCRIPTION
    Uses a .NET library to workaround limitations of the built-in ConvertTo-Json CmdLet
    to enable Powershell objects to be rendered as a JSON-formatted string.

    #>

	[CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline=$true, Position=0)]
        [AllowNull()]
        $Input,

        [int32]
        $Depth = 2
    )

    try {
        # Test whether the type we need is already loaded
        [JsonPrettyPrinterPlus.PrettyPrinterExtensions] | Out-Null
    }
    catch {
        # type isn't loaded, so load it in a way that doesn't lock the file
        $dll = "{0}\..\..\lib\JsonPrettyPrinterPlus.dll" -f $PSScriptRoot
        _loadType $dll
    }

    # Convert to JSON using the more reliable -Compress option
    # (sometimes ConvertTo-Json will choke on certain objects when not using the -Compress option)
    $json = $Input | ConvertTo-Json -Depth $Depth -Compress
    
    # Use the external library to format it nicely
    return (_prettyPrint $json)
}