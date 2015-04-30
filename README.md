Logging
============

## Overview

The Write-Log was initially written as a script about 5 years ago.  It was built to address some problems with using Write-Host and other 'interactive' cmdlets in PowerShell.  Over time it has been turned into a module and now supports various outputs (through the use of providers) and detects the type of host it is running in so that things like Write-Host do not cause issue.

One of the more difficult aspects of logging with PowerShell is that it is not easy to get an object back of the message, if it has been output by one of the standard PowerShell commands.  This module will keep a record of all the messages that have been output which can be requested by the script or module that is using it.  This allows sophisticated analysis to be performed on the messages if so required.

It is not uncommon for many modules to have a reliance on Logging.  Logging has the ability to have different parameters set for different modules that consume it.  So for example POSHChef may require output to the screen, but if it uses another module, which output is to be ignored the log parameters for that module can be set accordingly so as not to pollute the output of information.

This module is a dependency for POSHChef and must be installed in order to use POSHChef.

## Installation

This is to be deployed as a module.  Copy the contents of the repository to the following location:

    C:\Windows\System32\WindowsPowerShell\v1.0\Modules\Logging

Note:  This is currently the location for the module, but it may change in the future to fit in with the additional module locations that Microsoft Provides in Windows.

## More Information

Please refer to the [Wiki](http://github.com/POSHChef/Logging/wiki) for more detailed installation information and further information.

## Acknowledgements

This project makes use of the following open source projects:

- [Json Pretty Printer](http://www.markdavidrogers.com/json-pretty-printerbeautifier-library-for-net/)
