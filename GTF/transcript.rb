#! /bin/env/ruby

# read genomic sequence from fasta file
$sequence = ""
File.open(ARGV[1].to_s, "r") do |file|
    
    # delete first line
    file.gets
    
    line = file.gets
    while !line.match(/^>/) && !file.eof?
        
        $sequence += line.chomp    
        line = file.gets
    end
    $sequence += line
end

File.open(ARGV[0].to_s, "r") do |file|
    
    gene = Hash.new
    
    file.each_line do |feature|
    
        hold =  feature.split(/\s/, 8)
        
        transcript_pattern = /transcript_id\s+"([^"]+)"\s*;/
        hold[-1] =~ transcript_pattern
        transcript_id = $1
        
        gene_pattern = /gene_id\s+"([^"]+)"\s*;/
        hold[-1] =~ transcript_pattern
        transcript_id = $1
        
        
        
        
    end


end
