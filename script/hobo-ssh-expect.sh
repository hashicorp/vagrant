#!/usr/bin/expect

set uname [lrange $argv 0 0]
set password [lrange $argv 1 1]
set host [lrange $argv 2 2]
set port [lrange $argv 3 3]

if { $port != "" } {
  set port_option "-p $port"
} else {
  set port_option ""
}

spawn ssh $port_option $uname@$host

expect "*password: " {
  sleep 1
  send "$password\r"
} timeout {
  send_user "Error connecting"
}

interact
