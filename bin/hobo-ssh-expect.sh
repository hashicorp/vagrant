#!/usr/bin/expect

set uname [lrange $argv 0 0]
set password [lrange $argv 1 1]
set host [lrange $argv 2 2]

spawn ssh $uname@$host

expect "*password: " {
  sleep 1
  send "$password\r"
} timeout {
  send_user "Error connecting"
}

interact
