#!/usr/bin/ruby
require 'net/http'
uri = URI('http://www.baidu.com')
data = Net::HTTP.get(uri)
data.scan(/<a href="(http.*?)"/) { |x| puts x }
