#! /usr/bin/ruby

require 'test/unit/assertions'
include Test::Unit::Assertions

# Take a file, get all the lines until matching termination_pattern.
# We are searching for // in particular, which are the termination characters
# for the cds.
# TODO: make the method general for any String object, and not for file objects.
def get_sequence(file, termination_pattern, keep_last = nil)
  assert(file.class == File, "#{file} is not a valid File object.")
  assert(termination_pattern.class == Regexp, "#{termination_pattern} is not a valid Regexp object.")
  out = ""
  line = file.gets

  # Continue reading file lines until file ends or
  # line match termination_pattern
  while (!file.eof? && !line.match(termination_pattern)) do
    out += line
    line = file.gets  # read next line
  end
  if keep_last
    out += line
  end
  if (!line.match(termination_pattern))
    abort("Error: Cannot find termination pattern.")
  end

  out
end

# group sequence in 80 characters lines long
# the 80-th character is '\n'
# TODO: try to pass sequence by reference (think 'yeld' statement
# is involved)
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

# Given a complete CDS sequence (trimmed and concatenated),
# calculates sequence codons distribution
def frequency_distribution (sequence, length_pattern)
  assert(length_pattern > 0, "The pattern length must be grater than 0")
  frequency = Hash.new
  index = 0
  while index < sequence.length do
    codon = sequence[index .. index + length_pattern - 1]
    frequency[codon] == nil ? frequency[codon] = 1 : frequency[codon] += 1
    index += length_pattern
  end
  frequency
end

def make_genome_mapping (file)
  assert(file.class == File, "#{file} is not a valid File object.")
  base_map = Hash.new

  file.each_line do |line|
    if line.match(/\s*Stop\s*/)
     #next
    else
      terms = line.split(/,|(\s*,)|\n/)
      amino_acid = terms[0]
      terms = terms[3..terms.length]
      terms.each do |base|

        base_map[base] = amino_acid
        end
    end
  end
  base_map
end

def base_mapping (base_map, sequence)

  length_pattern = base_map.keys[0].length
  out = ""
  index = 0
  while index < sequence.length do
    codon = sequence[index .. index + length_pattern - 1]
    out += base_map[codon].to_s
    index += length_pattern
  end

  out
end

##########################--MAIN--##############################################
# define global variable will contains the output text
$out = ""
$MAX_LENGTH = 80 # Max length for sequence lines in the output file
$cds = 0
$amino_in = "" # It's the cds of the input file that we want to match
# TODO: should be better to first read all the file, store its value on
# a String, then process the String.
# TODO: add safety against miss parameters
File.open(ARGV[0].to_s, "r") do |inp|

  # Here we define all the elements needed to compose
  # the final output file.
  # Once we have processed the file, we chain togeter these elements.

  alph = /[ACGT]/ # Regexp object representing the sequence alphabet

  ac  = ""
  len   = ""
  mrna = nil

  org   = ""
  desc  = ""
  gene = ""

  start_cds = 0
  end_cds   = 0
  cds = ""  # Should be easy to obtain once we have start/end_cds...
  # keep for readability

  tot_sequence = ""
  cds_sequence = ""
  id_line = ""

  inp.each_line do |line|

    case line
      when /^ID.+/
        id_line = line

      when /^\s*OS.+/
        tmp = line.split
        tmp = tmp[1..tmp.length]
        org += '"' + tmp.join(" ") + '"'

      when /^\s*DE.+/
        tmp = line.split
        tmp = tmp[1..tmp.length]
        desc = tmp.join(" ")
        i_to_remove = desc =~ /\s*\.+$/
        if i_to_remove
          i_to_remove == 0 ? desc = "" : desc = desc[0..i_to_remove - 1]
        end
        desc = '"' + desc + '"'

      when /^\s*SQ.*/
        tot_sequence = get_sequence(inp, /^\s*\/\/\s*/)

      when /\s*^FT\s+CDS\s+([+-]*\d+)\s*\.\.\s*([+-]*\d+)\s*/
        start_cds = $1.to_i
        end_cds = $2.to_i
        cds += start_cds.to_s + ".." + end_cds.to_s

      when /\s*^FT\s+\/gene\s*=\s*"(\w+)"\s*/
        # /gene appears more the once in the file, so I try to just
        # keep the first occurence
        if gene.length == 0
          gene += $1
        end
      when /\s*^FT\s+\/translation\s*=\s*"(\w*)\s*/
        tmp = $1
        tmp2 = get_sequence(inp, /"/, true)
        tmp2 = tmp2.split
        tmp2.each do |word|
          if word != "FT"
            tmp += word
          end
        end
        $amino_in = tmp[0..tmp.length - 2] # I need to delete the "
    end
  end

  # id_line after this statement is a completely new object, I've just
  # reused the same name for convenience
  id_line = id_line.split(/;|\./)
  id_line.each do |sep|
    case sep
      when /^\s*ID\s*(\w+)\s*/
        ac = $1
      when /\s*(\d+)\s+BP\s*/
        len += $1.to_s + "bp"
      when /\s*mRNA\s*/
        mrna = true
      end
  end

  # Operate on code sequence, removing sequence indexes from lines and
  # chaining together the whole sequence
  temp_sequence = ""
  tot_sequence = tot_sequence.upcase
  tot_sequence.split.each do |part|
    if part.match(alph)
      temp_sequence += part
    end
  end

  tot_sequence = temp_sequence
  # We have the cleaned sequence, the start and end indexes of the coding
  # sequence, so we can get the cds (if presents) from the total sequence managing
  # tot_sequence as an array of String (char in Ruby doesn't exists).
  # N.B: Strings in Ruby start from 0! so -1 from start_cds and end_cds
  if (start_cds != end_cds)
    if (start_cds < 1 ||
      end_cds > tot_sequence.length ||
      end_cds < 0)
      abort ("Error: Invalid cds index")
    end

    cds_sequence = tot_sequence[(start_cds - 1 .. end_cds - 1)]
  end

  # group sequence in lines whose length is <=80 (the 80-th
  # character is \n)
  $cds = cds_sequence
  grouped_sequence = group_sequence(tot_sequence, $MAX_LENGTH)
  grouped_cds = group_sequence(cds_sequence, $MAX_LENGTH)

end

File.open(ARGV[1].to_s, "r") do |map_file|
  genome_map = make_genome_mapping(map_file)

  amino_acid_seq = base_mapping(genome_map, $cds)
  amino_distrib = frequency_distribution(amino_acid_seq, 1)

  assert($cds.length % 3 == 0, "Sequence must be multiple of 3.")
  codon_distrib = frequency_distribution($cds, 3)

  $out = ">Distribuzione delle frequenze dei codoni\n"
  codon_distrib.each do |key, value|
    $out += key.downcase.to_s + " => " + value.to_s + "\n"
  end
  $out += ">Traduzione della CDS\n"
  $out += group_sequence(amino_acid_seq, 60) + "\n"
  $out += ">Distribuzione delle frequenze degli aminoacidi\n"
  amino_distrib.each do |key, value|
    $out += key.upcase.to_s + " => " + value.to_s + "\n"
  end

  amino_acid_seq == $amino_in ?
    $out += "La traduzione della CDS coincide con la traduzione riportata nel file input" :
    $out += "La traduzione della CDS non coincide con la traduzione riportata nel file input"

  print $out
end
