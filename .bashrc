
#####################################
#########      Conf      ############
#####################################

BASE_BASHRC=$HOME/.bashrc
BASHRC_DIR=$HOME/.bash
BASHRC=$BASHRC_DIR/.bashrc

### Input configuration ###
# Set keyboard repeat delay / rate
xset r rate 200 65
# Set mouse wheel speed value in ~/.imwheel
if command -v imwheel > /dev/null; then
    imwheel --kill &> /dev/null
fi

### PATH ###
export PATH=$PATH:$HOME/.scripts


### PS1 ###
PS1="$PS1 \e[1;4;32m\$(__git_ps1 | cut -c 2-)\e[0m\n$ "


### Bashrc ###
alias sourcerc='source $BASE_BASHRC'
alias bashrc='emacs $BASHRC; sourcerc'
alias gotobash='pushd $BASHRC_DIR'


### Bash Tools ###
alias ret='echo $?'
alias uncolor="sed -r \"s/\\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g\""

mkcd ()
{
    mkdir -p $1
    cd $1
}

### Git ###
alias gg="git gui"
alias gk="gitk"

### Custom autocomplete  ###

# Reference increment
incr ()
{
    eval "${1}=$(($1 + 1))"
}



## Case-insensitive compgen
# Format: compgen -W "liste de mots" -- mot-ref (le même que la builtin bash)
# Print les mots de la liste de mots dont mot-ref est le préfixe, case-insensitive
my_compgen ()
{
    if [ $1 = "-W" ]; then
	if [ $# = 3 ]; then # empty candidate string (it is therefore not even passed as the fourth argument
	    echo $2
	fi
        local s=${@: -1}
        for i in $2; do
            if [[ ${i,,} = ${s,,}* ]]; then # magic bash sugar for case-insensitive prefix testing
                echo $i
             fi
         done
    else
        # Forward à la builtin ce qu'on ne gère pas
        builtin compgen $@
    fi
}

MOMO_FID=0

compfuncgen ()
{
    body="if [ \$COMP_CWORD -eq 1 ]; then
        COMPREPLY=( \$(my_compgen -W \"$1\" -- \$cur) );"
    shift
    local j=2
    for i in "$@"; do
        body+=" elif [ \$COMP_CWORD -eq $j ]; then
        COMPREPLY=( \$(my_compgen -W \"$i\" -- \$cur) );"
        j=$(($j + 1))
    done
    body+=" fi"
    eval "function _complete$MOMO_FID ()
    {
        local cur=\${COMP_WORDS[COMP_CWORD]}
        $body
    }"
}

# complete du futur
my_complete ()
{
    if [ $1 = "-W" ]; then
        eval "function _complete$MOMO_FID ()
        {
            local cur=\${COMP_WORDS[COMP_CWORD]}
            if test -n \$cur; then
                COMPREPLY=( \$(my_compgen -W \"$2\" -- \$cur) )
            else
                COMPREPLY=( $2 )
            fi
         }"
        builtin complete -F _complete$MOMO_FID $3
        incr MOMO_FID
    elif [ $1 = "--futur" ]; then
        local name=$2
        shift 2
        compfuncgen "$@"
        builtin complete -F _complete$MOMO_FID $name
        incr MOMO_FID
    else
        # Forward à la builtin des cas non gérés
        builtin complete $@
    fi
}

format_usage ()
{
    if [ "$1" != -bypass ]; then #rec
        $(format_usage -bypass -noarg "[-bypass] [-noarg] ARGS...")
    else
        shift
    fi

    local cond=""
    if [ "$1" = -noarg ]; then
        cond=" || [ \$# = 0 ]"
        shift
    fi
    FORMAT="if [ \"\$1\" = \"-h\" ] $cond; then
        echo Usage:;"
        for i in "$@"; do
            FORMAT+="echo -e \"\t\$FUNCNAME $i\";";
        done;
        FORMAT+="return;
        fi;"

     echo "eval $FORMAT"
}
my_test ()
{
    echo "I am a test function" $@
}

duplog ()
{
    script -efq -c "$1" | tee "$1".log
}

PROJECTS="app engine"
PLATFORMS="android html5 linux64 ui"
TEEST="aa ab ac ad ae af ba"
my_complete --futur my_test "$TEEST" "$PROJECTS" "$PLATFORMS"
complete -c duplog
