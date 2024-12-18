# utility_scripts

* no dependencies
* works for both bash and zsh

* develop ONLY functions in `./src`
* dont use source command in any files in `./src`
* if something depends on each other, make the dependency resolution by putting dependant files with lower numbers
* type `make requirements && make compile` to concat and minify all script files
* use only compiled and minified `build/*` files for sourcing in external projects

* also contains `standalone_scripts` which are some nice everyday scripts to use (scripts consist of enhanced functionalities
  which you cannot implement in one or two functions), see README.md in the sub-folder

NOTES: 
* functions in here MUST HAVE ZERO EXTERNAL DEPENDENCIES!!!
* no internal linking allowed, which means not sourcing any of the files in between
* if you need access from one files data or functions to another one internally, put the content together in ONE file


## how to start

to first time init run

```bash
./__makefile_init_run_only_once.sh
```

if you want to compile without former init run

```bash
./__first-time-run.sh
```

Note: after running `make clean` you need to run `./__init.sh` again

Note: to compile you need preprocess python package, install with 

```bash
$ pipx install preprocess
$ export PATH=~/.local/bin:$PATH
$ make compile

```

