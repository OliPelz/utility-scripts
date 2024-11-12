# no shebang line here, for sourcing ONLY, works in both bash and zsh
# shebang is not working in sourced files!


# file contains:
# * color definitions in dict
# * all functions using those color dict to print some kind of colored output

: '
Color Definition Source file 

ShortDesc: This script defines color codes for both Bash and Zsh shells, supporting various text styles.

Description:
The script provides an associative array `colors` that contains different color codes and text styles.
It supports normal colors, bold, high intensity, and bold high intensity colors. The color definitions
differ between Bash and Zsh due to their unique syntax requirements. For Bash, ANSI escape codes are used,
while for Zsh, prompt formatting is utilized. The `reset` color is used to return the terminal text back
to its default appearance.

Usage Example:

	source <THIS COLOR DEFINITION SOURCE FILE> 

    # To use the defined colors in Bash
    if [ -n "$BASH_VERSION" ]; then
        echo -e "${colors["red"]}This is red text in Bash${colors["reset"]}"
    elif [ -n "$ZSH_VERSION" ]; then
        print -P "${colors[red]}This is red text in Zsh${colors[reset]}"
    fi

Parameters:
- None

Returns:
- Sets the `colors` associative array for use in terminal output.


'


if [ -n "$BASH_VERSION" ]; then
    : '
    Bash Color Definitions

    - Declare an associative array named colors.
    - Each color is defined using ANSI escape codes.
    '
	declare -A bash_colors

    # Define Bash colors
    bash_colors["black"]="\033[0;30m"
    bash_colors["red"]="\033[0;31m"
    bash_colors["green"]="\033[0;32m"
    bash_colors["yellow"]="\033[0;33m"
    bash_colors["blue"]="\033[0;34m"
    bash_colors["purple"]="\033[0;35m"
    bash_colors["cyan"]="\033[0;36m"
    bash_colors["white"]="\033[0;37m"
    # Bold
    bash_colors["bblack"]="\033[1;30m"
    bash_colors["bred"]="\033[1;31m"
    bash_colors["bgreen"]="\033[1;32m"
    bash_colors["byellow"]="\033[1;33m"
    bash_colors["bblue"]="\033[1;34m"
    bash_colors["bpurple"]="\033[1;35m"
    bash_colors["bcyan"]="\033[1;36m"
    bash_colors["bwhite"]="\033[1;37m"
    # High Intensity
    bash_colors["iblack"]="\033[0;90m"
    bash_colors["ired"]="\033[0;91m"
    bash_colors["igreen"]="\033[0;92m"
    bash_colors["iyellow"]="\033[0;93m"
    bash_colors["iblue"]="\033[0;94m"
    bash_colors["ipurple"]="\033[0;95m"
    bash_colors["icyan"]="\033[0;96m"
    bash_colors["iwhite"]="\033[0;97m"
    # Bold High Intensity
    bash_colors["biblack"]="\033[1;90m"
    bash_colors["bired"]="\033[1;91m"
    bash_colors["bigreen"]="\033[1;92m"
    bash_colors["biyellow"]="\033[1;93m"
    bash_colors["biblue"]="\033[1;94m"
    bash_colors["bipurple"]="\033[1;95m"
    bash_colors["bicyan"]="\033[1;96m"
    bash_colors["biwhite"]="\033[1;97m"
    # Reset
    bash_colors["reset"]="\033[0m"

elif [ -n "$ZSH_VERSION" ]; then
    : '
    Zsh Color Definitions

    - Use a typeset associative array to define colors.
    - Colors are defined using Zsh prompt formatting.
    '
    typeset -A zsh_colors

    # Define Zsh colors using prompt formatting
    zsh_colors=(
        [black]="%F{black}"
        [red]="%F{red}"
        [green]="%F{green}"
        [yellow]="%F{yellow}"
        [blue]="%F{blue}"
        [purple]="%F{magenta}"
        [cyan]="%F{cyan}"
        [white]="%F{white}"
        # Bold
        [bblack]="%F{black}%B"
        [bred]="%F{red}%B"
        [bgreen]="%F{green}%B"
        [byellow]="%F{yellow}%B"
        [bblue]="%F{blue}%B"
        [bpurple]="%F{magenta}%B"
        [bcyan]="%F{cyan}%B"
        [bwhite]="%F{white}%B"
        # High Intensity
        [iblack]="%F{black}"
        [ired]="%F{red}"
        [igreen]="%F{green}"
        [iyellow]="%F{yellow}"
        [iblue]="%F{blue}"
        [ipurple]="%F{magenta}"
        [icyan]="%F{cyan}"
        [iwhite]="%F{white}"
        # Bold High Intensity
        [biblack]="%F{black}%B"
        [bired]="%F{red}%B"
        [bigreen]="%F{green}%B"
        [biyellow]="%F{yellow}%B"
        [biblue]="%F{blue}%B"
        [bipurple]="%F{magenta}%B"
        [bicyan]="%F{cyan}%B"
        [biwhite]="%F{white}%B"
        # Reset
        [reset]="%f%b"
    )
fi


