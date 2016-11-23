require 'test/unit/assertions'
include Test::Unit::Assertions

def extract_read(line, programs)
    read_array = line.split
    cigar = read_array[5]
    m_array = cigar.scan(/(\d+)M/).flatten

    # how to do it with mapcar?
    tot = 0
    m_array.each do |m|
        tot += m.to_i
    end

    line =~ /PG:Z:(\w+)/
    current_pg = $1
    current_pg == nil ? pg_str = "" : pg_str = "program: #{programs[current_pg]}, "

    out =  "{qname: #{read_array[0]}, " +
            "rname: #{read_array[2]}, " +
            pg_str +
            "align_pos: #{read_array[3]}, " +
            "m_number: #{tot}}"
    out
end


File.open(ARGV[0].to_s, "r") do |file|

    pg = Hash.new
    out = ""
    file.each_line do |line|
        case line
            when /^@PG/
                line =~ /ID:(\w+)/
                assert($1 != nil, "@PG must include a valid ID, given:" + line)
                id = $1
                line =~ /PN:(\w+)/
                assert($1 != nil, "@PG must include a valid PN, given:" + line)
                pn = $1
                pg[id] = pn

            when /^r.+/
                out += extract_read(line, pg) + "\n"
        end
    end
    puts out
end
