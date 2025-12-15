#!/bin/zsh

# ./gts-sessionizer.sh

# Note: You should add a keybind in tmux as well 
# bind-key o display-popup -E -w 80% -h 80% '<path_to>/gts-sessionizer.sh'

REQUIRED_PKG="tmux gum zoxide"

for PKG in $REQUIRED_PKG; do
    if [ -z "$(which $PKG)" ]; then
        printf "REQUIRED: %s\n" "$PKG"
        printf "Please install missing package using Brew\n"
        printf "\n\tbrew install %s\n" "$PKG"
        exit 1
    fi
done

TICKET_DIRECTORY="$HOME/Downloads"
TICKET_PREFIX="Ticket_"
US_ONLY_PREFIX="US_ONLY_"
CREATE_TICKET="Create a New Ticket"
QUERY_LIMIT=10

function newTicket () {

    # Create a US ONLY Ticket or Normal Ticket
    gum confirm "Create a US ONLY Ticket?" --affirmative No --negative Yes && local_prefix=$TICKET_PREFIX || local_prefix=$US_ONLY_PREFIX

    printf "Creating %sXXXX ticket...\n" "$local_prefix"
    # prompt for ticket number
    while true; do
        number=$(GUM_CHOOSE_HEIGHT=20 gum input --prompt="Enter Ticket Number > " --placeholder="0123456789")
        # check if user press Ctrl+C or ESC
        if [ -z "$number" ]; then
            exit 0
        fi
        
        # Check that it is a number
        if [[ $number =~ ^[0-9]+$ ]]; then
            break
        fi
    done

    ticket_dir_name="$local_prefix$number"

    # check if ticket folder exists, if not create it
    if [ ! -d "$TICKET_DIRECTORY/$ticket_dir_name" ]; then
        printf "Ticket Directory doesn't exist, creating it...\n"
        mkdir -p "$TICKET_DIRECTORY/$ticket_dir_name"
    else
        printf "Ticket Directory already exists!\n"
    fi

    # call openWorkspace
    openWorkspace "$ticket_dir_name"
}

function openWorkspace () {

    session_name=$1

    if [ "$(tmux list-session -F '#{session_name}' | grep -c $session_name)" -eq 0 ]; then
        # create new detached session
        tmux new-session -d -s $session_name -c $TICKET_DIRECTORY/$session_name
    fi
    # switch to session
    tmux switch-client -t $session_name

}

function menu () {

    # display ordering of most frequent ticket workspace to least
    array_one=("$CREATE_TICKET" $(zoxide query $TICKET_DIRECTORY/ -l | head -n$QUERY_LIMIT | xargs -I {} basename {} | grep "$TICKET_PREFIX\|$US_ONLY_PREFIX"))
    array_two=($(find $TICKET_DIRECTORY -type d -name '$US_ONLY_PREFIX*' -print0 | xargs -0 -I {} basename {} | sort -r) $(find $TICKET_DIRECTORY -type d -name '$TICKET_PREFIX*' -print0 | xargs -0 -I {} basename {} | sort -r))
    declare -a array_menu
    declare -A seen_elements

    for element in "${array_one[@]}"; do
        array_menu+=("$element")
        seen_elements["$element"]=1
    done

    for element in "${array_two[@]}"; do
        if [ -z "${seen_elements[$element]}" ]; then
            array_menu+=("$element")
            seen_elements["$element"]=1
        fi
    done

    choice=$(gum choose "${array_menu[@]}")

    if [ "$choice" == "$CREATE_TICKET" ]; then
        # create new ticket
        newTicket
    else
        # call openWorkspace
        openWorkspace "$choice"
    fi
}

# CALL MENU
gum style --border normal --padding '1 2' --margin '1 1' --width 99 --align center -- 'GTS Sessionizer'
menu
