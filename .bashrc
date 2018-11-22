
#####################################
#########      Conf      ############
#####################################

BASE_BASHRC=$HOME/.bashrc
BASHRC_DIR=$HOME/.bash
BASHRC=$BASHRC_DIR/.bashrc
SCRIPTS_DIR=$HOME/.scripts

### Input configuration ###
# Set keyboard repeat delay / rate
xset r rate 180 80
# Set mouse wheel speed value in ~/.imwheel
if command -v imwheel > /dev/null; then
    imwheel --kill &> /dev/null
fi

### PATH ###
export PATH=$PATH:$HOME/.scripts

### Default editor for some commands (i.e. cron, incron) ###
export VISUAL=emacs

### Java
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/


### PS1 ###
# \r trick for right align
PS1_cpy="$PS1"
#PS1='$(set_ps1)'
set_ps1()
{
#    echo -e $(printf "%s%$((${COLUMNS}+1))s%s\r%s" "\e[1m" '$?' "\e[0m" "$PS1 \e[1;4;32m\$(__git_ps1 | cut -c 2-)\e[0m\n$ ")
    echo -e "$PS1_cpy \e[1;4;32m$(__git_ps1 | cut -c 2-)\e[0m\n$ "
}
PS1=$(printf "%s%$((${COLUMNS}+1))s%s\r%s" "\e[1m" '$?' "\e[0m" "$PS1 \e[1;4;32m\$(__git_ps1 | cut -c 2-)\e[0m\e[34m \$(date +%H:%M:%S)\e[0m\n$ ")

### Bashrc ###
alias sourcerc='source $BASE_BASHRC'
alias bashrc='emacs $BASHRC; sourcerc'
alias gotobash='pushd $BASHRC_DIR'
alias gotoscripts='pushd $SCRIPTS_DIR'


### Bash Tools ###
alias e=emacs
alias lcat=lolcat
alias lll='ll --time-style=full-iso'
alias uncolor="sed -r \"s/\\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g\""

ret ()
{
    local return_value="$?"
    echo "$return_value"
    return "$return_value"
}

mkcd ()
{
    mkdir -p $1
    cd $1
}

isnumber ()
{
    local re='^[0-9]+$'
    if [ $# = 0 ]; then
        return 1
    fi
    if [[ $1 =~ $re ]]; then
        return 0
    fi
    return 1
}

# do history
mode ()
{
    local cmd
    while :; do
        # PS1 du pauvre
        echo -en "\e[1;92m$USER@$HOSTNAME:\e[34m$PWD\n\e[95m\$ [$1]\e[39m "
        read cmd
        eval "$1 $cmd"
    done
}
complete -c mode

### Git ###
alias ga="git add"
alias gg="git gui"
alias gk="gitk"
alias gst="git status"
alias gckt="git checkout" # FIXME ; __git_complete gckt _git_checkout
alias gf="git fetch"
alias gdiff="git diff"
alias gpl="git pull"
alias gl="git log"
alias gcm="git commit"

# TODO: make it generic
alias check-todo='git diff-index -G TODO HEAD'
alias check-fixme='git diff-index -G FIXME HEAD'

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

duplog ()
{
    script -efq -c "$1" | tee "$1".log
}
complete -c duplog

my_test ()
{
    $(getopt -a 1 ---name -b 2 ---pos)
}

getopt ()
{
    local body
    read -d '' body << EOM
for arg in "\$@"; do
    if [ "\$arg" = "-h" ]; then
        echo "It works!";
    else
        echo \$arg;
    fi;
done;
EOM
    local i=0
    local opt
    local opts
    local arity
    local arities
    local name
    local names
    while [ $# != 0 ]; do
        opt="$1"
        shift

        arity="$1"
        if isnumber $arity; then
            shift
        else
            arity=1
        fi

        name=""
        if [ "$(echo $1 | cut -c 1-3)" = "---" ]; then
            name=$(echo $1 | cut -c 4-)
            shift
        fi

        opts[$i]="$opt"
        arities[$i]="$arity"
        names[$i]="$name"
        incr i
    done
    for i in $(seq 0 ${#opts[@]})
    do
        : #echo "${opts[$i]} ${arities[$i]} ${names[$i]}"
    done

    echo "eval $body"
}


# unset -f FUNNAME
# unset VARNAME

PROJECTS="app engine"
PLATFORMS="android html5 linux64 ui"
TEEST="aa ab ac ad ae af ba"
my_complete --futur my_test "$TEEST" "$PROJECTS" "$PLATFORMS"
