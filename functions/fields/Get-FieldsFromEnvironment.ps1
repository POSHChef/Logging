

function Get-FieldsFromEnvironment {

  <#

  .SYNOPSIS
    Gets fields and values from named environment variables

  .DESCRIPTION
    As part of configuring Logging it is possible to state which environment variables should
    be observed that contain name/value pairs of extra fields that need to be added to the
    logging message.

    Not all providers will support this, but those that do will be passed a hashtable of
    fields to add to their log structure.

    This function will extract all the fields from the specified environment variables and return
    a hashtable of the names and values

  #>

  [CmdletBinding()]
  param (

    [string[]]
    # String array of the environment variables to look for
    $envvars
  )

  # Check to see if any environment variables have been set.  if not return to the calling function
  # with an empty hashtable
  if ($envvars.count -eq 0) {
    return @{}
  }

  # Creat the fields hashtable that will be returned to the calling function
  $fields = New-Object System.Collections.hashtable

  # Environment variables have been set so iterate around each of them obtaining the field and value
  foreach ($envvar in $envvars) {

    # Work out the path to the environment variable so it can be checked for existence
    $env_path = "Env:{0}" -f $envvar

    # check to see if the environment variable exists, if it does not then continue onto the next iteration
    if (!(Test-Path -Path $env_path)) {
      continue
    }

    # Get the value from the environment variable and split on the '=' symbol to provide the field and the value
    $envvar_value = (Get-Item -Path $env_path).Value

    # Check that the $envvar_value matches the name/value pattern
    if (($envvar_value -notmatch '((?:\\.|[^=,]+)*)=("(?:\\.|[^"\\]+)*"|(?:\\.|[^,"\\]+)*)')) {
      continue
    }

    $field, $value = $envvar_value -split "="

    # add the field and the value to the fields hashtable
    $fields.add($field, $value) | Out-Null

  }

  # return
  return $fields
}
