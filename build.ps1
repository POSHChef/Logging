
# Build script for packaging up the Logging module
#
# This script is used by the MyGet Build service
#
# Author: Russell Seymour
# Company: Turtlesystems Consulting

param (
  [string]
  # Version to apply to the build
  $version = [String]::Empty
)

# Determine paths to required utilities
$nuget = $env:Nuget
if ([String]::IsNullOrEmpty($nuget)) {
  $nuget = "nuget"
}

# Get the version from the environment if it has not been set
if ([String]::IsNullOrEmpty($version)) {
  $version = $env:PackageVersion
}

# set a flag to denote if the tests have failed
$tests_failed = $false

# Ensure that the command Invoke-Pester is available
$pester_available = Get-Command -Name Invoke-Pester -ErrorAction SilentlyContinue

# only run test if pester is available
if (![String]::IsNullOrEmpty($pester_available)) {

  # Invoke-Pester from the current location and get the results back
  $results = Invoke-Pester -Path . -Passthru

  # If there are failed tests then abort the build
  if ($results.FailedCount -gt 0) {

    $message = "##myget[buildProblem description='Build failed, {0} tests failed']" -f $results.failedcount
    Write-Output $message

    # update flag
    $tests_failed = $true
  }
}

# if the tests have not failed package up the module
if (!$tests_failed) {

  # If there then the tests have passed so attempt to build the package
  . $nuget pack Logging.nuspec -version $version -nopackageanalysis
}
