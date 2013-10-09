#!/bin/bash
echo "Updating The Exploit-DB"
cd /usr/share/exploitdb/
wget http://www.exploit-db.com/archive.tar.bz2
tar -xvjf /usr/share/exploitdb/archive.tar.bz2
rm /usr/share/exploitdb/archive.tar.bz2
echo "Exploit-DB Update Finished"
