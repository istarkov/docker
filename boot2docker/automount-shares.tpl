#!/bin/sh
set -e

#mount -o nolock 192.168.59.3:/Users
while ! ip addr | grep 192.168.59 > /dev/null; do sleep 1; done

HOST_VBOX_IP={IP}

mountOptions='defaults'
if grep -q '^docker:' /etc/passwd; then
	mountOptions="${mountOptions},uid=$(id -u docker),gid=$(id -g docker)"
fi


# try mounting "$name" (which defaults to "$dir") at "$dir",
# but quietly clean up empty directories if it fails
try_mount_share() {
	dir="$1"
	name="${2:-$dir}"
	
	echo $dir "***" $name
	mkdir -p "$dir"
	if ! mount -o nolock "$HOST_VBOX_IP":"$name" "$dir"; then
		rmdir "$dir" 2>/dev/null || true
		while [ "$(dirname "$dir")" != "$dir" ]; do
			dir="$(dirname "$dir")"
			rmdir "$dir" 2>/dev/null || break
		done
		
		return 1
	fi
	
	return 0
}

# bfirsh gets all the credit for this hacky workaround :)
try_mount_share /Users 'Users' \
	|| try_mount_share /Users \
	|| try_mount_share /c/Users 'c/Users' \
	|| try_mount_share /c/Users \
	|| try_mount_share /c/Users 'c:/Users' \
	|| true
