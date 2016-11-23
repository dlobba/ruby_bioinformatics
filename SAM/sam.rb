require 'test/unit/assertions'
include Test::Unit::Assertions


File.open(ARGV[0].to_s, "r") do |file|
    
    pg = Hash.new
    
    file.each_line do |line|
        puts line
        case line
            when /@PG/
                line =~ /ID:(\+w)/
                puts $1
                assert($1 != nil, "@PG must include a valid ID, given:" + line)
                id = $1
                line =~ /PN:(\w+)/
                assert($1 != nil, "@PG must include a valid PN, given:" + line)
                pn = $1
                
                pg[id] = pn
                
        end
    end
    puts pg.to_s
end