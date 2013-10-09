#!/usr/bin/ruby
#@upker.net
puts "[+]ResolveIp.rb"
puts "[-]\@upker.net"
print "[+]Usage:",__FILE__," urlfile format(default 0)\n"
require 'resolv'
if ($*[0] == "")
exit
end

puts "----------------------------------------------------"
file = File.open($*[0], "r")
file.each do |uri|
uri=uri.sub(/[\r\n]/,"")
if ($*[1] == "1")
	begin
	print Resolv.getaddress(uri),"\n"
	rescue
	end
else
	begin
	print uri,"->",Resolv.getaddress(uri),"\n"
	rescue
	end
end
end
puts "----------------------------------------------------"
file.close
puts "[+]All Done."
