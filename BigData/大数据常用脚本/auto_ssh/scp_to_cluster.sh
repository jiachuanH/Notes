#!/usr/bin/expect

set timeout 10
set user "Ryan" 
set pw "000000" 

set ip [lindex $argv 0]
set shell_dir [lindex $argv 1]
set remote_dir [lindex $argv 2]
set shell_file "auto_ssh/gen_key.sh"

#puts "$shell_dir*"
#puts "$remote_dir"
puts "========================== copy file from local ======================="
spawn /usr/bin/scp -r $shell_dir $user@$ip:$remote_dir
expect {
    "Connection refused" exit
    "Name or service not known" exit
    "continue connecting" {send "yes\r";exp_continue}
    "password:" {send "$pw\r";exp_continue}
} 

sleep 1

puts "======================== run shell on remote server ========================="
spawn ssh $user@$ip  "${remote_dir}/${shell_file}"
expect {
    "Connection refused" exit
    "Name or service not known" exit
    "continue connecting" {send "yes\r";exp_continue}
    "password:" {send "$pw\r";exp_continue}
    interact;exit
} 

exit


