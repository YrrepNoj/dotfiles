#!/bin/bash


MoveAppToWindow(){

    appName=$1
    windowNum=$2


    commandString="yabai -m query --windows | jq -r '.[] | select(.app == \"${appName}\") | .id'"
    ids=$(eval ${commandString})
    echo "The ids we have: " $ids " for " $appName
    id_array=($ids)
    for id in "${id_array[@]}" 
    do
        yabai -m window --focus $id
        yabai -m window --space $windowNum
        # sleep 0.5
    done 
}

main() {

    touch "/Users/jon/thing-ran.out"

    ## Focus space 1 so that we don't get stuck in an infinate error loop
    yabai -m space --focus 1

    ## Make sure we have enough spaces for everything we want to do!
    yabai -m space --focus 6
    SPACE_CHECK=$?
    for ((dummy = 0 ; SPACE_CHECK != 0 ; dummy++));
    do
        yabai -m space --create
        yabai -m space --focus 6
        SPACE_CHECK=$?
    done



    ## Get all the Apps and move them to Workspace 6
    app_ids=$(yabai -m query --windows | jq -r '.[] | .id')
    app_id_array=($app_ids)
    echo "List of all app IDs" $app_ids
    for id in "${app_id_array[@]}" 
    do
        yabai -m window --focus $id
        yabai -m window --space 6
    done 

    ################ Workspace 1 ################ 
    ##### Dev Apps: (VSCode, iTerm, Chrome) #####
    MoveAppToWindow "Google Chrome" 1
    MoveAppToWindow "Code" 1
    MoveAppToWindow "iTerm2" 1


    ################ Workspace 2 ################ 
    ##### Personal Apps: (Canary, Discord) #####
    MoveAppToWindow "Google Chrome Canary" 2
    MoveAppToWindow "Discord" 2

    ################ Workspace 3 ################ 
    ##### Social Apps: (Slack, Gather) #####
    MoveAppToWindow "Slack" 3
    MoveAppToWindow "Gather" 3


    ################ Workspace 4 ################ 
    ##### Notes: Obsidian, Notion, Linear #####
    MoveAppToWindow "Obsidian" 4
    MoveAppToWindow "Linear" 4
    MoveAppToWindow "Notion" 4

    ## Go back to the first space
    yabai -m space --focus 1
}

main