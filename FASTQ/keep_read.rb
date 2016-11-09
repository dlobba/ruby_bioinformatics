#! /usr/bin/ruby

require 'test/unit/assertions'
include Test::Unit::Assertions

q = ARGV[1].to_i
p = ARGV[2].to_i

def ascii_to_quality (char)
    assert(char.class == String, "Character expected, given: #{char}")
    assert(char.length != 0, "Expected character, given String: #{char}")
    out = char.ord - 33
end

def quality_to_ascii (quality)
    assert(quality.class == Fixnum)
    out = ([quality, 93].min + 33).chr
end

def count_quality_bases (sequence, q_star)
    counter = 0
    sequence.split("").each do |char|
        quality = ascii_to_quality(char)
        quality >= q_star ? counter += 1 : counter
    end
    counter
end

$out = ""

File.open(ARGV[0].to_s, 'r') do |file|

    while !file.eof? do
        
        line1 = file.gets.chomp
        line2 = file.gets.chomp
        line3 = file.gets.chomp
        line4 = file.gets.chomp
        
        sequence_quality = count_quality_bases(line4, p) / line4.length
        
        if sequence_quality > p
        
            $out +=  [line1, line2, line3, line4].join("\n")
        
        end
    end
end

puts $out
