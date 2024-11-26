# standalone_scripts

## NOTES: 
* standalone scripts without any external dependency
* ideal for vanilla systems, because they contain proxy and download functionalities
* scripts in here MUST HAVE ZERO EXTERNAL DEPENDENCIES!!!
* exception is linking to local common.sh file
* for all other, no internal linking allowed, which means not sourcing any of the files in between
* if you need access from one files data or functions to another one internally, put the content together in ONE file

a collection of publicly available scripts

## common.sh script file

* the common.sh script file is ideal to hardcopy into new vanilla projects on systems which dont have any network setup
  because it can download files behind proxy, so this is the place to start

