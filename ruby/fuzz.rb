#!/usr/bin/ruby

file = File.open("fuzz.txt","r+")
for i in 0..65536 do
	file.print "A"
end
file.close
