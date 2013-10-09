#!/usr/bin/ruby
require 'rubygems'
require 'exifr'

obj = EXIFR::JPEG.new('1.jpg')
if obj.exif?
  puts "--- EXIF information ---".center(50)
  hash= obj.exif.to_hash
  hash.each_pair do |k, v|
    puts "-- #{k.to_s.rjust(20)} -> #{v}"
  end
  obj.exif.make = "hack"
end
