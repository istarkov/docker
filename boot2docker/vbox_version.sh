#!/usr/bin/env sh
 
get_vbox_version(){
    local VER
    VER=$(VBoxManage -v | awk -F "r" '{print $1}')
    if [ -z "$VER" ]; then
        echo "ERROR"
    else
        echo "$VER"
    fi
 
}
 
write_vbox_dockerfile(){
    local VER
    VER=$(get_vbox_version)
    echo $VER
}
 
write_vbox_dockerfile