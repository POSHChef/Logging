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

param
(
    [hashtable] $configuration
)

# Get a list of the functions that need to be sourced
$Functions = Get-ChildItem -Recurse "$PSScriptRoot\functions" -Include *.ps1 | Where-Object { $_ -notmatch "Providers" }

# source each of the individual scripts
foreach ($function in $functions) {
	. $function.FullName
}

# get a list of the functions that need to be expotred
$functions_to_export = $Functions | Where-Object { $_.FullName -match "Exported"} | ForEach-Object { $_.BaseName }

# Export the accessible functions
Export-ModuleMember -function ( $functions_to_export )

# Declare variable that will hold the log targets etc when other functions need to use Write-Log
$Logging = @{}

# Allow consumers to specify their configuration at import time 
# e.g. if they have re-load the module they can restore their original config
if ($configuration) {
    Write-Verbose "Initialising Logging module with explicit configuration"
    $Logging = $configuration
}
