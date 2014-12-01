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


function Get-LogParameters {

	<#

	.SYNOPSIS
	Returns the current logging parameters

	.DESCRIPTION
	When a module is unloaded that has links to another module, functions within that module
	can cease to be accessible.  In this case the only way to get them back is to reimport the module.
	This function will return the current logging parameters so that when a module is unlaoded, and it
	takes out Logging then the parameters can be sent back in

	#>

	$Script:Logging
}
