#!/bin/sh

set -e
set -x

# Delete and recreate ssh keys.
rm -rf /root/.ssh/
ssh-keygen -q -t ed25519 -N "" -f /root/.ssh/id_ed25519

# Add the host details so that we can ssh and rsync easily.
cat > /root/.ssh/config << EOF
Host vm
	HostName 127.0.0.1
	User root
	Port 10022
EOF

# Compile and install the search binary.
cc ./.ci/srch.c -o /usr/local/bin/srch

# Compile and install the usleep binary.
cc ./.ci/usleep.c -o /usr/local/bin/usleep

# Sends the string in the first argument slowly one char at a time at typing
# speeds to the tmux window.
tmux_sendkeys_slow(){
tmp="$1"
while [ -n "$tmp" ]
do
 rest="${tmp#?}"
 first="${tmp%"$rest"}"
 tmux send-keys -l "$first"
 usleep 100000
 tmp="$rest"
done
}

# Installs the required programs.
apt -y install sshfs net-tools

# Download the DFBSD image.
wget https://github.com/vmactions/dragonflybsd-builder/releases/download/v0.9.8/dragonflybsd-6.4.2.qcow2.zst -O /tmp/dfbsd.qcow2.zstd

# Unpack the VM image.
zstd --rm -d /tmp/dfbsd.qcow2.zstd -o /tmp/dfbsd.qcow2

# Create a tmux session that the VM  will start in.
tmux new-session -d

# Get the hosts number of CPUs.
hncpu=$(getconf _NPROCESSORS_ONLN)

# TODO: The memory amount found in the VM is not accurate we should fix this.
# Get the hosts amount of memory in megabytes.
#hmem=$(( $(sysctl -n hw.physmem)/1024/1024 ))

# Send the VM start command.
tmux send-keys -l "qemu-system-x86_64 -enable-kvm -drive file=/tmp/dfbsd.qcow2,if=ide -m 7G,maxmem=7G -smp $hncpu -device e1000,netdev=n1 -netdev user,id=n1,hostfwd=tcp:127.0.0.1:10873-:873,hostfwd=tcp:127.0.0.1:10022-:22 -nographic"

# Start the VM.
tmux send-keys Enter

# Store the VM console output.
tmux pipe-pane -O "cat >> /tmp/vm-log" 

# Waiting for BIOS to start.
(tail -f -n +1  /tmp/vm-log & ) | srch 'DF/FBSD' 

# Boot the default BIOS option without waiting.
tmux send-keys Enter 

# Waiting for loader to start.
(tail -f -n +1  /tmp/vm-log & ) | srch 'Booting in'

# Stop the loader boot timer.
tmux send-keys -l " "

# Wait for it to stop.
(tail -f -n +1  /tmp/vm-log & ) | srch 'Countdown'

# Get into the loader prompt.
tmux send-keys -l "9"
tmux send-keys Enter

# Wait for the prompt to appear.
(tail -f -n +1  /tmp/vm-log & ) | srch 'OK'

# The loader prompt will bug out when we send the keys too fast. So we need to
# send the keys and normal typing speeds.

# Enable the serial console.
tmux_sendkeys_slow 'set console=comconsole'
sleep 1
tmux send-keys Enter
sleep 1

# Boot the kernel.
tmux_sendkeys_slow 'boot'
sleep 1
tmux send-keys Enter

# Wait for getty to appear and login.
(tail -f -n +1  /tmp/vm-log & ) | srch 'login:'

# Login with the root user.
tmux send-keys -l 'root'
tmux send-keys Enter

tmux send-keys -l 'unalias rm'
tmux send-keys Enter
# Add the hosts ssh key to VM.
tmux send-keys -l 'rm -rf /root/.ssh/*'
tmux send-keys Enter
tmux send-keys -l 'touch /root/.ssh/authorized_keys'
tmux send-keys Enter
tmux send-keys -l 'chmod 600 /root/.ssh/authorized_keys'
tmux send-keys Enter
sleep 1
tmux_sendkeys_slow -l 'echo "'"$(cat /root/.ssh/id_ed25519.pub | tr -d "\n")"'" >>  /root/.ssh/authorized_keys'
sleep 1
tmux send-keys Enter

# Add the VM to the known hosts.
ssh-keyscan -p 10022 127.0.0.1 > /root/.ssh/known_hosts

# We now have ssh and will use it for the further commands.

# Set the VM's nameserver.
ssh vm "echo 'nameserver 1.1.1.1' > /etc/resolv.conf" 

modprobe fuse
mkdir /mnt/vm
sshfs -o reconnect -o delay_connect vm:/ /mnt/vm

# Setup the rsync server on the VM
cat >> /mnt/vm/usr/local/etc/rsync/rsyncd.conf << 'EOF'
[vmshare]
path = /
comment = VM root share
uid = 0
gid = 0
read only = no
list = yes
EOF
ssh vm 'service rsyncd onestart'

# Setup the rsync server on the host
mkdir /tmp/share
cat >> /etc/rsyncd.conf << 'EOF'
[hostshare]
path = /tmp/share
comment = host share
uid = 0
gid = 0
read only = no
list = yes
EOF
rsync --daemon

# Add the host IP to the VM 
hostip=$(ifconfig ens4 | awk '/inet / {print $2}') 
echo "${hostip} host.vm.run host" >> /mnt/vm/etc/hosts

