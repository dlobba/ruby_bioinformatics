#! /usr/bin/ruby

require 'test/unit/assertions'
include Test::Unit::Assertions

# performs merge sort sorting a1 and a2 according
# to a1 values
def merge_sort (a1, a2, l, r)
    if l < r then
        m = (l + r) / 2
        merge_sort(a1, a2, l, m)
        merge_sort(a1, a2, m + 1, r)
        merge(a1, a2, l, m, r)
    end
end

def merge (a1, a2, l, m, r)
    i = l
    j = m + 1
    k = 0
    b1 = Array.new
    b2 = Array.new

    while i <= m && j <= r
        if a1[i] <= a1[j]
            b1[k] = a1[i]
            b2[k] = a2[i]
            i += 1
        else
            b1[k] = a1[j]
            b2[k] = a2[j]
            j += 1
        end
        k += 1
    end

    while i <= m
        b1[k] = a1[i]
        b2[k] = a2[i]
        i += 1
        k += 1
    end

    while j <= r
        b1[k] = a1[j]
        b2[k] = a2[j]
        j += 1
        k += 1
    end

    k = l
    while k <= r
        a1[k] = b1[k-l]
        a2[k] = b2[k-l]
        k += 1
    end
end

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
    temps = @transcript[:begins]
    tempe = @transcript[:ends]
    merge_sort(temps, tempe, 0, temps.length - 1)

    temps.length.times do |index|
      from  = temps[index] - 1
      to    = tempe[index] - 1
      out +=  sequence[from .. to]
    end
    @strand == "-" ? self.reverse_n_complement(out) : out
  end

  def find_nearest_start (sorted_transcript, cds)
    if sorted_transcript[:begins][0] > cds
        return 0
    end

    max = sorted_transcript[:begins].length - 1
    if sorted_transcript[:begins][max] < cds
        return max + 1
    end

    index = 0
    while index < max
        if  sorted_transcript[:begins][index] <= cds &&
            sorted_transcript[:ends][index] >= cds
            return index
        end
        index += 1
    end
    index - 1
  end

  def find_nearest_end (sorted_transcript, cds)
    if sorted_transcript[:begins][0] > cds
        return nil
    end

    index = 0
    while index < sorted_transcript[:begins].length
        if  sorted_transcript[:begins][index] <= cds &&
            sorted_transcript[:ends][index] >= cds
            return index
        end
        index += 1
    end
    index
  end

  # must be given a sorted transcript sequences
  def expand_cds (sorted_transcript, cds_s, cds_e)

      assert(cds_e <= cds_e, "Invalid cds, start: #{cds_s} end: #{cds_e}.")

      s = sorted_transcript[:begins].find_index(cds_s)
      e = sorted_transcript[:ends].find_index(cds_e)

      if s == e && s != nil
          return [[cds_s], [cds_e]]
      end

      if s == nil
          s = find_nearest_start(sorted_transcript, cds_s)
          assert(s < sorted_transcript[:begins].length, "Invalid start cds: #{cds_s}.")
      end

      if e == nil
          e = find_nearest_end(sorted_transcript, cds_e)
          assert(e != nil, "Invalid cds end: #{cds_e}.")
      end

      if sorted_transcript[:begins][s] > cds_s
          cds_s = sorted_transcript[:begins][s]
      end

      if sorted_transcript[:ends][e] < cds_e
          cds_e = sorted_transcript[:ends][e]
      end
      if s == e
          return [[cds_s], [cds_e]]
      end

      # Now we are sure that cds doesn't fit into an exon
      starts = Array.new
      ends   = Array.new
      starts.push(cds_s)
      ends.push(sorted_transcript[:ends][s])

      index = s + 1 # could have just kept s...
      while index < e
          starts.push(sorted_transcript[:begins][index])
          ends.push(sorted_transcript[:ends][index])
          index += 1
      end
      starts.push(sorted_transcript[:begins][index])
      ends.push(cds_e)

      [starts, ends]
  end

  # transcript already sorted
  def complete_cds (sorted_begin, sorted_end)
      temps = Array.new
      tempe = Array.new
      cds_ss = @cds[:begins]
      cds_es = @cds[:ends]
      merge_sort(cds_ss, cds_es, 0, cds_ss.length - 1)
      cds_ss.length.times do |index|
          in_between = expand_cds({:begins => sorted_begin, :ends => sorted_end}, cds_ss[index], cds_es[index])
          temps += in_between[0]
          tempe += in_between[1]
      end
      return [temps, tempe]
  end

  def extract_cds (sequence)
    # perform these operation without modifying
    # the cds sequence given,
    # althouh this is resource and time consuming
    # this is supposed to be called just once per
    # execution
    temps = @transcript[:begins]
    tempe = @transcript[:ends]
    merge_sort(temps, tempe, 0, temps.length - 1)
    hold = complete_cds(temps, tempe)
    temps = hold[0]
    tempe = hold[1]

    out = ""
    temps.length.times do |index|
      from  = temps[index] - 1
      to    = tempe[index] - 1
      out +=  sequence[from .. to]
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
    transcript = self.extract_transcript(sequence)
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
