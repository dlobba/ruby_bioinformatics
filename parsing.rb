# Take a file, get all the lines until matching termination_pattern.
# We are searching for // in particular, which are the termination characters
# for the cds.
# TODO: make the method general for any String object, and not for file objects.
def get_sequence(file, termination_pattern)
    
    # Don't know how to import assert library: TODO
    #assert (file.class == File, "#{file} is not a valid File object.")
    #assert (pattern.class == Regexp, "#{termination_pattern} is not a valid Regexp object.")
    out = ""
    line = file.gets
    matchp = !!line.match(termination_pattern) # initialize to False to enter the loop
    
    # Continue reading file lines until file ends or
    # line match termination_pattern
    while (!file.eof? && !line.match(termination_pattern)) do
        out += line
        line = file.gets  # read next line
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
def group_sequence (sequence)

    temp_sequence = ""
    index = 0; cont = 0
    while sequence[index] != nil do
        temp_sequence += sequence[index]
        index += 1
        if cont < $MAX_LENGTH - 1
            cont += 1
        else
            temp_sequence += "\n"
            cont = 0
        end
    end
    temp_sequence
end


##########################--MAIN--##############################################

# define global variable will contains the output text
$out = ""
$MAX_LENGTH = 80 # Max length for sequence lines in the output file

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
    tot_sequence = group_sequence(tot_sequence)
    cds_sequence = group_sequence(cds_sequence)
    
    # print output
    
    if (tot_sequence.length == 0)
        abort("Error: Invalid EMBL")
    end
    
    $out =  [">" + ac, "/length=" + len , "/org=" + org, "/desc=" + desc].join(" ")
    $out += "\n" + tot_sequence + "\n"
    if (mrna)
        $out += [">" + ac, "/cds=" + cds , "/gene=" + gene].join(" ")
        
        # Check for start codon and end codon
        $out += " " + (cds_sequence[0..2].match(/ATG/) ?
                        "/start_codon=YES" : "/start_codon=NO")
        $out += " " + (cds_sequence[cds_sequence.length - 3 .. cds_sequence.length].match(/(TAG)|(TAA)|(TGA)/) ?
                        "/stop_codon=YES" : "/stop_codon=NO")
        $out += "\n" + cds_sequence
    end
end

if (ARGV[1] != nil)
    File.open(ARGV[1].to_s, "w") do |out|

        out.write($out + "\n")

    end
else
    puts $out
end
