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


function Set-LogParameters {

	<#

	.SYNOPSIS
	Sets various settings for the Write-Log function

	.DESCRIPTION
	Write-Log needs to know what resources file to use, the location of the additional providers directory,
	and the options that need to passed.  This function sets the module variable that can be read by the
	Write-Log function.  This avoids the need for global variables

	The function adds a custom hash within the logging object.  This is so that configuration data can be set
	for additional providers that Write-Log might consume

	#>

	[CmdletBinding()]
	param (

		[array]
		[Parameter(ParameterSetName="switches")]
		# Output targets
		# This list denotes the targets that the message for write-log should be sent to
		$targets = @( @{logProvider="screen"; verbosity="Info";} ),

		[string]
		[Parameter(ParameterSetName="switches")]
		[alias("helpfile")]
		# Help Resources
		# Path to the resources file that contains the messages to be used when invoking write-log
		$resource_path = [String]::Empty,

		[string]
		[Parameter(ParameterSetName="switches")]
		# Providers
		# Path to another directory that contains providers that Write-Log can use
		$providers = [String]::Empty,

		[Parameter(ParameterSetName="switches")]
		# Custom
		# This allows extra configuration to be passed to the Write-Log function
		# Such use cases will be for custom providers that have been written
		# If not set this item will not appear in the logging object
		$custom = $false,

		[Parameter(ParameterSetName="object")]
		# Parameters
		# This is an object that contains all of the settings that need to be defined in the module
		$parameters,

		[hashtable]
		# Module that is setting the parameters
		$module = @{},

		[Parameter(ParameterSetName="switches")]
		[string[]]
		# List of environment variables to look at when building up the log message
		$envvars = @()
	)

	# determine if the module has been set
	# get the name if it has
	if ($module.Count -gt 0) {
		$module_name = ($module.GetEnumerator()).name
	}

	# determine if the session loggin module has this as a key
	# if so grab that as the local logging otherwise use the default
	if (![String]::IsNullOrEmpty($module_name) -and $script:Logging.containskey($module_name)) {
		$local_logging = $script:Logging.$module_name.clone()
	} else {
		$local_logging = $script:Logging.clone()
	}

	# set the logging hashtable up based on the paramater set
	switch ($PsCmdlet.ParameterSetName) {

		"switches" {

			# Set the logging variable accordingly

			# If log targets have been set specifically then override anything in the logging variable
			if (![String]::IsNullOrEmpty($targets)) {
				$local_logging.targets = $targets
			}

			# Set additional providers
			# If any have been specified then override those in the loggin variable
			if (![String]::IsNullOrEmpty($providers)) {
				$local_logging.providers_path = $providers
			}

			# Attempt to load the specified resources file
			if (![String]::IsNullOrEmpty($resource_path) -and ($local_logging.ContainsKey("resource")) -eq $false) {

				# If the file exists then read it in as a XML object
				if (Test-Path -Path $resource_path) {

					[xml] $local_logging.resource = Get-Content -Path $resource_path -Raw

				} else {

					Write-Warning -Message ("Unable to load helpfile as it cannot be located.`n`t{0}" -f $resource_path)
				}

			}

			# Set a user attribute that can be set by parameters
			if (!($local_logging.ContainsKey("custom")) -and $custom -ne $false) {
				$local_logging.custom = $custom
			}

			# set the environment variables
			if ($envvars.count -gt 0) {
				$local_logging.envvars = $envvars
			}

		}

		"object" {

			$local_logging = $parameters

		}

	}

	# If the Logging session does not have a module key add it now
	if (!$local_logging.containskey("module")) {
	  $local_logging.module = @{
	    path = $PSScriptRoot
	  }
	}

	# Add an array that will hold any messages that are passed to the module
	# so that they can be output as part of a pipeline at the end
	$script:Logging.messages = @()

	# The module variable is accessible at the script scope level
	# This is added to the logging based on the module, if it has been specified
	if ([String]::IsNullOrEmpty($module_name)) {
		$script:Logging = $local_logging
		$script:Logging.module_settings = $false
	} else {

		Write-Verbose "Adding module specific settings: $module_name"

		# set the variable up so that it knows modules have set different parameters
		$script:Logging.module_settings = $true

		# of the session logging variable does not contain a key of the module name, set it now
		if ($script:Logging.containskey($module_name) -eq $false) {
			$script:Logging.add($module_name, @{})
		}

		if ($script:Logging.$module_name.containskey("functions") -eq $false) {
			$script:Logging.$module_name.add("functions", @());
		}

		# set the local function $logging on the logging var for the module
		$script:Logging.$module_name = $local_logging
		$script:Logging.$module_name.functions = $module.$module_name

	}

}
