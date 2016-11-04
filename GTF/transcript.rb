#! /usr/bin/ruby

# it's quite a fat class
# TODO: Separate string function utility from this class
class Feature
    attr_accessor(:transcript, :cds, :_5utr, :_3utr)
    @gene_id
    @transcript_id
    @start_codon
    @stop_codon 
    @source
    @strand
    @transcript
    @cds 
    @_5utr
    @_3utr
    
  # if ruby-version > 2.0 we can use keyword parameters  
  def initialize(gene_id, transcript_id, strand, source)
    @gene_id = gene_id
    @transcript_id = transcript_id
    @strand = strand
    @source = source
    
    @transcript = Hash.new
    @transcript[:begins] = Array.new
    @transcript[:ends] = Array.new
    
    @cds = Hash.new
    @cds[:begins] = Array.new
    @cds[:ends] = Array.new
    
    @_5utr = Hash.new
    @_3utr = Hash.new  
  end
  
  def extract_transcript (sequence)
    out = ""
    @transcript[:begins].length.times do |index|
      from  = @transcript[:begins][index] - 1
      to    = @transcript[:ends][index] - 1
      if @strand == "-"
        out = sequence[from .. to] + out
      else
        out +=  sequence[from .. to]
      end
    end
    @strand == "-" ? self.reverse_n_complement(out) : out
  end
  
  def extract_cds (sequence)
    out = ""
    @cds[:begins].length.times do |index|
      from  = @cds[:begins][index] - 1
      to    = @cds[:ends][index] - 1
      if @strand == "-"
        out = sequence[from .. to] + out
      else
        out +=  sequence[from .. to]
      end
    end
    @strand == "-" ? reverse_n_complement(out) : out
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
  
  def transcript_fasta (sequence)
    transcript = self.extract_transcript (sequence)
    out = ">/source=" + @source + " " +
          "/gene_id=" + @gene_id + " " +
          "/transcript_id=" + @transcript_id + " " +
          "/type=transcript " +
          "/length=" + transcript.length.to_s + " " +
          "/strand=" + @strand + "\n" +
          group_sequence(transcript, 80)
  end
  
  def cds_fasta (sequence)
    cds = self.extract_cds (sequence)
    
    if cds.length == 0
      return nil
    end
    
    out = ">/source=" + @source + " " +
          "/gene_id=" + @gene_id + " " +
          "/transcript_id=" + @transcript_id + " " +
          "/type=cds " +
          "/length=" + cds.length.to_s + " " +
          "/strand=" + @strand + " " +
          "/start_codon=" + (cds.length > 2 && cds[0 .. 2].match(/ATG/) ? "YES" : "NO") + " " +
          "/stop_codon=" + (cds.length > 2 && cds[-3 .. -1].match(/(TAG)|(TAA)|(TGA)/) ? "YES" : "NO") + "\n" +
          group_sequence(cds, 80)
  end
  
  # copy_pasted and adapted from previous projects
  def group_sequence (sequence, length)
    temp_sequence = ""
    index = 0; cont = 0
    while sequence[index] != nil do
      temp_sequence += sequence[index]
      index += 1
      if cont < length - 1
        cont += 1
      else
        # if next char doesn't exist and cont == length we don't need to escape
        # it perfectly matches length
        sequence[index] == nil ? temp_sequence : temp_sequence += "\n"
        cont = 0
      end
    end
    temp_sequence
  end
end

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

    # Make an hash table containing the features referenced
    # by a key which is the sum of gene_id and transcript_id
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
          hold = Feature.new(gene_id.to_s,
                              transcript_id.to_s,
                              temp[6].to_s,
                              temp[0])
        else
          hold = features[key]
        end
        
        case temp[2]
          when "exon"
            hold.transcript[:begins].push(temp[3].to_i)
            hold.transcript[:ends].push(temp[4].to_i)
          when "CDS"
            hold.cds[:begins].push(temp[3].to_i)
            hold.cds[:ends].push(temp[4].to_i)
        end
        features[key] = hold
    end
    $transcript_out = ""
    $cds_out = ""
    features.each do |key, feature|
      $transcript_out += feature.transcript_fasta($sequence) + "\n"
      cds = feature.cds_fasta ($sequence)
      cds == nil ? $cds_out : $cds_out += cds + "\n"
    end
    print $transcript_out, $cds_out
end
