file = File.open(ARGV[0].to_s)

base_map = Hash.new  
file.each_line do |line|

  if line.match(/\s*Stop\s*/)
    next
  else
    
    terms = line.split(/,|(\s*,)|\n/)
    puts terms.to_s
    
    amino_acid = terms[0]
    terms = terms[3..terms.length]
    terms.each do |base|
    
      base_map[base] = amino_acid
    end 
  end
  
end

puts base_map

