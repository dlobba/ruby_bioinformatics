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

def group_sequence (sequence, length)
  temp_sequence = ""
  index = 0; cont = 0
  while sequence[index] != nil do
    temp_sequence += sequence[index]
    index += 1
    if cont < length - 1
      cont += 1
    else
      temp_sequence += "\n"
      cont = 0
    end
  end
  temp_sequence
end

def make_feature()

    # This is basically a class... this is not good... but it works... for now
    # TODO Do a class Feature
    feature = Hash.new
    feature[:gene_id] = nil
    feature[:transcript_id] = nil
    feature[:type] = nil
    feature[:start_codon] = nil
    feature[:stop_codon] = nil 
    feature[:source] = nil
    feature[:strand] = nil
    feature[:transcript] = Hash.new
    feature[:transcript][:begins] = Array.new
    feature[:transcript][:ends]   = Array.new
    feature[:cds] = Hash.new
    feature[:cds][:begins] = Array.new
    feature[:cds][:ends] = Array.new
    feature[:_5UTR] = Hash.new
    feature[:_5UTR][:begins] = Array.new
    feature[:_5UTR][:ends]   = Array.new
    feature[:_3UTR] = Hash.new
    feature[:_3UTR][:begins] = Array.new
    feature[:_3UTR][:ends]   = Array.new
    return feature

end

def reverse_n_complement (sequence)
  out = ""
  sequence.split("").each do |char|
    
    case char.upcase
      when "A"
        
        out += "T"
      when "T"
        out += "A"
      when "C"
        out += "G"
      when "G"
        out += "C"
    end
  end
  out.reverse
end


File.open(ARGV[0].to_s, "r") do |file|
    
    features = Hash.new
    file.each_line do |feature|
        
        temp =  feature.split(/\s/, 8)
        transcript_pattern = /transcript_id\s+"([^"]+)"\s*;/
        temp[-1] =~ transcript_pattern
        transcript_id = $1
        
        gene_pattern = /gene_id\s+"([^"]+)"\s*;/
        temp[-1] =~ gene_pattern
        gene_id = $1
        
        key = gene_id.to_s + transcript_id.to_s
        
        if features[key] == nil
          hold = make_feature
          hold[:gene_id] = gene_id.to_s
          hold[:transcript_id] = transcript_id.to_s
          hold[:strand] = temp[6].to_s
          hold[:source] = temp[0]
        else
          hold = features[key]
        end
        
        case temp[2]
          when "exon"
            hold[:transcript][:begins].push(temp[3].to_i)
            hold[:transcript][:ends].push(temp[4].to_i)
          when "CDS"
            hold[:cds][:begins].push(temp[3].to_i)
            hold[:cds][:ends].push(temp[4].to_i)
        end
        features[key] = hold
    end
    # puts features
    $out = ""
    features.each do |key, transcript|
      
        $out += ">/source=" + features[key][:source] + " " +
                "/gene_id=" + features[key][:gene_id] + " " +
                "/transcript_id=" + features[key][:transcript_id] + " "

        transcript = ""
        features[key][:transcript][:begins].length.times do |index|
            from  = features[key][:transcript][:begins][index] - 1
            to    = features[key][:transcript][:ends][index] - 1
            if features[key][:strand] == "-"
              transcript = $sequence[from .. to] + transcript
            else
              transcript +=  $sequence[from .. to]
            end
        end

        $out += "/type=transcript /length=" + transcript.length.to_s + " " +
        "/strand=" + features[key][:strand] + "\n"
        if features[key][:strand] == "-"
              transcript = reverse_n_complement(transcript)
        end
        $out += group_sequence(transcript, 80) + "\n"
    end
    
    puts $out
end
