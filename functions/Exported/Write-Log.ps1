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


function Write-Log {

	<#

	.SYNOPSIS
	Output a log message to specified providers

	.DESCRIPTION
	Output a structured messages to specified providers.  This is so that other log providers, e.g. Redis and ElasticSearch
	can be easily supported

	The providers are stored in a folder alongside this function, and an extra provider directory can be supplied as well.  If
	this is the case then both directories are analysed and the providers merged together.  Those with the same name will be
	overridden; those in the specified user directory will take precedence.

	Any provider must support the same function and arguments.

	The function can take an eventid which it will use to look up the message in a resources file.  The message text will then
	be extracted and this is what will be added to the structured data.

	#>

	[CmdletBinding()]
	param (

		[string]
		# EventID of the the message to be looked up
		$eventid = [String]::Empty,

		[alias("resource")]
		# Resource file
		# This can be a string, in which case it will be take as the filename to use
		# or if an object it will be used as is
		$help_resource,

		[Parameter(ValueFromPipeline=$true, Position=0)]
		[AllowNull()]
		[string]
		# The message that should be sent to the logging provider
		# This will override any message that has been supplied by the eventid
		$message = [String]::Empty,

		[ValidateSet("Error", "Warn", "Progress", "Info", "Verbose", "Debug")]
		[alias("messagetype")]
		[string]
		$loglevel = "Info",

		# Extra information that needs to be displayed inline in the message, using string formatting
		# or to be displayed on a new line in the message
		$extra = $false,

		[array]
		# a string array of the providers that should be called to output this message
		$targets = "undefined",

		[int]
		# Number of indents that should be applied to the message, this is only relevant
		# to providers that output to a screen or a text file
		$indent = 0,

		[alias("foregroundColor")]
		[ConsoleColor]
		# Colour of the text
		$fgcolour,

		[alias("backgroundColor")]
		[ConsoleColor]
		# Background colour of the text
		$bgcolour,

		[switch]
		# Specify of the text should be sent without a newline
		$nonewline,

		[string]
		[alias("providers")]
		# Path to a directory containing more log providers
		$path = [String]::Empty,

		[switch]
		# State if this is a WARN message
		$WarnLevel,

		[switch]
		# State if this is a WARN message
		$ProgressLevel,

		[switch]
		# State if message is a DEBUG message
		$IfDebug,

		[switch]
		# State if message is a VERBOSE message
		$IfVerbose,

		[switch]
		[alias("dryrun")]
		# State if in DryRun mode, this is useful to determine the functions
		# that might be run
		$IfDryRun,

		[alias("error")]
		[switch]
		# State if this is an ERROR message
		$ErrorLevel,

		[switch]
		# State if this is an INFO message, default
		$InformationLevel,

		[switch]
		# Whether the functions should exit after output, normally
		# used in conjunction with the Error flag
		$exit,

		[switch]
		# If running within a module, the exit function would exit the
		# powershells session.  Use this instead to force a return
		$stop,

		[switch]
		# If specified return the messages array
		$pipeline,

		[string]
		# Provide a hint to the function as to which module this command came from
		# this is to help with finding the correct module when functions of the same name
		# exist in different modules
		$module = [String]::Empty

	)

	Begin {

		if ($pipeline) {

			Write-Output $Script:Logging.messages

			return
		}

		# if the script:logging is set to module logging then get the approrpiate settings here
		if ($script:Logging.module_settings -eq $true) {

			# determine the name of the function that called write-log
			$calling_function = [System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.ScriptName)

			# determine the module that called Write-Log and then get the $logging settings
			if ([String]::IsNullOrEmpty($module)) {
				$calling_module = $script:Logging.keys | Where-Object { $script:Logging.$_.functions -icontains $calling_function }
			} else {
				$calling_module = $module
			}

		}

		Write-Verbose "Calling module: '$calling_module' ($($MyInvocation.ScriptName)"

		if (![String]::IsNullOrEmpty($calling_module) -and $Script:Logging.containskey($calling_module)) {

			$Logging = $script:Logging.$calling_module

		} else {

			# get a local variable of the module scope variable 'Logging'
			$Logging = $script:Logging

		}

		# if the script variable does not contain a messages array add it now
		if (!$script:Logging.ContainsKey("messages")) {
			$script:Logging.messages = @()
		}

		# Define function variables
		$indent_string = "    "
		$default_fgcolour = "white"
		$default_bgcolour = "black"
		$event_type = "Information"

		# if explicit logtargets have been set, use them rather than the module-level or default ones
		if ($targets[0] -eq "undefined") {
			if (![String]::IsNullOrEmpty($Logging.targets)) {
				$targets = $Logging.targets
			} else {
				# If no logTargets have been defined then just set a default screen looger
				$targets = @( @{logProvider="screen"; verbosity="Info";} )
			}
		}

		# if the resource is null then get this from the global as well
		if ([String]::IsNullOrEmpty($help_resource)) {
			$help_resource = $Logging.resource
		}

		# determine if the path has been set, and if not use the providers_path
		# in the logging variable
		if ([String]::IsNullOrEmpty($path)) {
			$path = $Logging.providers_path
		}

		# Built up the object that will be populated with the message information
		$message_structure = New-Object PSObject -Property @{

								# The name of the machine
								hostname = ($env:COMPUTERNAME)

								# set the eventid
								eventid = $eventid

								# set a holder for the level of the message
								level = "INFO"

								# set the severity of the messahe
								severity = ""

								# set the timestamp of the message
								timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")

								# add a placeholder for the message
								message = @{

									# the main text, this can be from the resource file or
									# a message tha has been passed to the function
									text = [String]::Empty

									# extra information that has been passed to the function
									extra = $null

								}
							}

		# If an eventid has been specified attempt to get the message from the resource file
		if (![String]::IsNullOrEmpty($eventid)) {

			# Determine the type of the help_resource
			# If it is a string assume it is a filename and attempt to load it as an XML document
			if ($help_resource -is [String]) {

				# Determine if the resource file can be found
				if (Test-Path -Path $help_resource) {

					# The file can be located, so read it in as an XML object
					[xml] $help_resource = (Get-Content -Path $help_resource) -join "`n"
				}
			}

			# Check that the resource that has been loaded is an XML document
			if ($help_resource -is [XML.XMLDocument]) {

				# get the message item from the xml document based on the XPath
				$xpath = "//resource[@code='{0}']" -f $eventid
				$item = $help_resource.SelectSingleNode($xpath)

				# set properties, but only if they have not been set by parametrers to the function
				# message
				if ([String]::IsNullOrEmpty($message)) {
					$message = $ExecutionContext.InvokeCommand.ExpandString($item.message)
				}

				# indent
				if ($indent -eq 0 -and $item.indent -gt 0) {
					$indent = $item.indent
				}

				# colours
				if (![String]::IsNullOrEmpty($item.colours)) {

					# foreground
					if ([String]::IsNullOrEmpty($fgcolour) -and (![String]::IsNullOrEmpty($item.colours.foreground))) {
						$fgcolour = $item.colours.foreground
					}

					# backrgound
					if ([String]::IsNullOrEmpty($bgcolour) -and (![String]::IsNullOrEmpty($item.colours.background))) {
						$bgcolour = $item.colours.background
					}
				}
			}
		}

		# Define the hierarchy of logging levels
        $verbositySettings = @{
                                None = 0;
                                Error = 1;
                                Warn = 2;
                                Progress = 3;
                                Info = 4;
                                Verbose = 5;
                                Debug = 6;
                            }

		$colourConfig = @{
			"error" = @{fgColour="red";}
			"warn" = @{fgColour="yellow";}
			"progress" = @{fgColour="green";}
			"info" = @{fgColour="white";}
			"verbose" = @{fgColour="yellow"; bgColour="black"}
			"debug" = @{fgColour="cyan";}
		}

		# work out the level of the message, based on the switches that have been set
		# this will also set the default colour for each level
		if ($IfVerbose) {
			$logLevel = "Verbose"
		}

		if ($IfDebug) {
			$logLevel = "Debug"
		}

		if ($IfDryRun) {
			$fgcolour = "magenta"
			$message_structure.level = "DRYRUN"
		}

		if ($ErrorLevel) {
			$logLevel = "Error"
		}

		if ($WarnLevel) {
			$logLevel = "Warn"
		}

		if ($ProgressLevel) {
			$logLevel = "Progress"
		}

		$message_structure.level = $logLevel.ToUpper()
		$event_type = $logLevel

		# Set the text colour based on the $colorConfig look-up table, if the fgcolour and bgcolour have not already been set
		if ($colourConfig.ContainsKey($logLevel) -and $colourConfig[$logLevel].fgColour -and [String]::IsNullOrEmpty($fgColour)) {
			$fgColour = $colourConfig[$logLevel].fgColour
		}

		if ($colourConfig.ContainsKey($logLevel) -and $colourConfig[$logLevel].bgColour -and [String]::IsNullOrEmpty($bgColour)) {
			$bgColour = $colourConfig[$logLevel].bgColour
		}

		# finally check the bgdolour, if it has not been set then set to the default
		if ($bgcolour -eq $null) {
			$bgcolour = $default_bgcolour
		}

		# get a list of the providers from the local providers path
		$provider_path = "{0}\..\..\Providers" -f $PSScriptRoot
		$providers = Get-ChildItem -Recurse -Path $provider_path -Include *.ps1

		# if an additional path has been set then add it to the providers array
		if (![String]::IsNullOrEmpty($path)) {

			# check that the path exists
			if (Test-Path -Path $path) {

				$providers += Get-ChildItem -Recurse -Path $path -Include *.ps1

			} else {

				Write-Warning -Message ("Path to additional providers cannot be found. ({0})" -f $path)
			}
		}
	}

	Process {

		# Determine if the message string has any placeholders in it, that need to be replaced by information
		# in the extra parameter
		if ($extra -ne $false) {

			# turn the extra information into an array, if it is not already one
			# this is so that it cne be easily subtituted inline or all elements output on a new line benath
			# the main message
			if ($extra -is [String]) {
				$extra = @($extra)
			} elseif ($extra -is [Hashtable]) {
				$extra = $extra.Keys | Sort-Object $_ | ForEach-Object {"{0}:  {1}" -f $_, ($extra.$_)}
			}

			# find out if there are any matches to {NUMBER} in the string
			$groups = [Regex]::Matches($message, "({[0-9]+})")
			if ($groups.Count -gt 0) {

				# set the message using formatting and the extra parameter as the 'splatting' of values
				$message = $message -f $extra

			} else {

				# the extra information is to be displayed on a new line
				$message_structure.message.extra = $extra
			}

		}

		# Set information in the message structure object
		$message_structure.message.text = $message

		# build up the splat hash to send to the provider function
		$parameters = @{

					structure = $message_structure

					indent = $indent
					indent_string = $indent_string

					fgcolour = $fgcolour
					bgcolour = $bgcolour

					nonewline = $nonewline

					event_type = $event_type
				 }

		# iterate around the target array and see if the target exists as an item in the providers
		foreach ($target in $targets) {

			# Check whether the current logTarget has a verbosity setting that should 'see' the current message
            $loggerVerbosityLevel = $verbositySettings[$target.verbosity]
            $messageVerbosityLevel = $verbositySettings[$logLevel]

            if ($loggerVerbosityLevel -ge $messageVerbosityLevel)
            {
				# determine if the provider exists
				$provider_file = $providers | Where-Object { $_.name -imatch ("^{0}" -f $target.logProvider) }

				# if the provider file is not null source it
				if (![String]::IsNullOrEmpty($provider_file)) {

					. ($provider_file.fullname)

					# Add parameters for the current provider to standard set
					$providerParameters = @{}
					$providerParameters += $parameters
					$providerParameters += $target

					# determine the parameters that the provider supports and create a splat hash
					# with only those keys
					$splat = @{}
					foreach ($param in (Get-Command Set-Message).Parameters.Keys) {

						# only add values to the splat that are not null
						if (![String]::IsNullOrEmpty($providerParameters.$param)) {
							$splat.$param = $providerParameters.$param
						}
					}

					# now invoke the provider by splatting the function
					"Set-Message @splat" | Invoke-Expression
				}
			}
		}

		# Always add the message to the messages array
		$script:Logging.messages += $message
	}

	End {
		# Determine if the function is to exit or stop the process
		# if exit, exit with the eventid
		if ($exit) {
			exit $eventid
		}

		if ($stop) {
			throw $eventid
		}
	}
}
