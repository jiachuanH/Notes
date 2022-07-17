#!/usr/bin/expect

set timeout 5
set user "Ryan" 
set pw "000000" 

set ip [lindex $argv 0]

spawn ssh-copy-id $user@$ip 

expect {
    "Connection refused" exit
    "Name or service not known" exit
    "continue connecting" {send "yes\r";exp_continue}
    "password:" {send "$pw\r";exp_continue}
} 


