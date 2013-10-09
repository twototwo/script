#!/usr/bin/ruby
file = File.open("domain.txt", "r+")
file.each do |line|
	line.scan(/([a-z]+\.[a-z]+\.[a-z]+)/)  { |x| puts x}
end
file.close
