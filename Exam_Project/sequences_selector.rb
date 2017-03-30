#! /usr/bin/ruby
class InvalidParameter < Exception
end


def show_help()

	tmp = "Sequences_selector\n Given a FASTA file it selects sequences that satisfy\n" +
	"the criterias defined by the parameters.\n" +
	"options:\n" +
	"-x <nth_sequence>\t\t --extracts the nth sequence if presents, the first sequence is the number 1\n" +
	"-X <from_sequence> <to_sequence> --extracts from the <from_sequence> " +
		"to the <to_sequence> sequences if present, extremes included\n" +
	"-H <header_string>\t\t --extacts all the sequences that contain <header_string> " +
		"in the header section\n" +
	"-C <content_string>\t\t --extracts all the sequences that contain <content_string> " +
		"in the content section of the sequence\n" +
	"-O <output_file>\t\t --saves the output to the specified <output_file>\n" +
	"-h \t\t\t\t --displays this help\n\n" +
	"FASTA comment that may be present in the file will be ignored. " +
	"The only accepted symbol to indicate an header line is the '>' \n(semicolon not allowed " +
	"even if on the first line).\n" +
	"If no options are specified then the whole file will be returned without any potential comment." 

	puts tmp
end

# "eats" each argument and checks its correctness, give in
# output an hash with the parameters parsed 
def process_parameters(array_parameter)

	tmp_array = array_parameter
	numeric_parameter = /^\d+$/
	
	# parameter initialization
	file_path = nil
	nth_sequence = nil
	from_sequence = nil
	to_sequence = nil
	header_condition = nil
	content_condition = nil
	file_output = nil
	show_help = false

	while !tmp_array.empty?

		case tmp_array[0]
		when "-x"
			# =~ fail if the element doesn't exist, so
			# there is no need to check its existence
			if numeric_parameter =~ tmp_array[1] && nth_sequence == nil
				nth_sequence = Integer(tmp_array[1])
				tmp_array = tmp_array.drop(2)
			else
				raise InvalidParameter.new ("An integer value for the sequence "\
					"requested is needed, given: " + tmp_array[1])
			end

		when "-X"
			if numeric_parameter =~ tmp_array[1] && numeric_parameter =~ tmp_array[2] && from_sequence == nil
				from_sequence = Integer(tmp_array[1])
				to_sequence = Integer(tmp_array[2])
				tmp_array = tmp_array.drop(3)
			else
				raise InvalidParameter.new ("Integers values for the sequences "\
					"requested are needed, given: " + tmp_array[1] + " " + tmp_array[2])
			end


		when "-H"
			if tmp_array[1] != nil && header_condition == nil
				header_condition = tmp_array[1]
				tmp_array = tmp_array.drop(2)
			else
				raise InvalidParameter.new ("A string for the header "\
					"condition is needed, given:" + tmp_array[1])
			end

		when "-C"
			if tmp_array[1] != nil && content_condition == nil
				content_condition = tmp_array[1]
				tmp_array = tmp_array.drop(2)
			else
				raise InvalidParameter.new ("A string for the header "\
					"condition is needed, given:" + tmp_array[1])
			end

		when "-h"
			if show_help == false
				show_help = true
				tmp_array = tmp_array.drop(1)
			end

		when "-O"
			if tmp_array[1] != nil && file_output == nil
				file_output = tmp_array[1]
				tmp_array = tmp_array.drop(2)
			else
				raise InvalidParameter.new ("A string for the output file "\
					"path is needed, given:" + tmp_array[1])
			end

		else
			if file_path == nil
				file_path = tmp_array[0]
				tmp_array = tmp_array.drop(1)
			else
				raise InvalidParameter.new ("A string for input "\
					"file path has already been given, found:" + tmp_array[0])
			end
		end
	end

	# cannot set both parameters at the same time
	if nth_sequence != nil && from_sequence != nil
		raise InvalidParameter.new("-x and -X options cannot be set at "\
			"the same time")
	end

	parameters = Hash.new()
	parameters[:file_path] = file_path
	parameters[:nth_sequence] = nth_sequence
	parameters[:from_sequence] = from_sequence
	parameters[:to_sequence] = to_sequence
	parameters[:header_condition] = header_condition
	parameters[:content_condition] = content_condition
	parameters[:file_output] = file_output
	parameters[:help] = show_help

	return parameters
end


# checks sequence against parameters and returns true
# if parameters are satisfied, otherwise returns false
def process_sequence(sequence, parameters)
	if parameters[:nth_sequence] != nil
		if sequence[:num_sequence] != parameters[:nth_sequence]
			return false
		end
	end

	if parameters[:from_sequence] != nil
		if sequence[:num_sequence] < parameters[:from_sequence] ||
			sequence[:num_sequence] > parameters[:to_sequence]
			return false
		end
	end

	if parameters[:header_condition] != nil
		if !sequence[:header].include?(parameters[:header_condition])
			return false
		end
	end

	if parameters[:content_condition] != nil
		if !sequence[:content].include?(parameters[:content_condition])
			return false
		end
	end

	return true
end


def sequences_selector (file_path, parameters, file_output)
	
	cap = -1 # default value
	if parameters[:nth_sequence] != nil
		cap = parameters[:nth_sequence]
	end

	if parameters[:to_sequence] != nil
		cap = parameters[:to_sequence]
	end

	File.open(file_path, "r") do |fasta_file|

		tmp_content = ""
		tmp_header = ""
		is_first_header = true
		num_sequence = 0
		
		#fasta_file.each_line do |line|
		while !fasta_file.eof? && (num_sequence <= cap || cap == -1)
			
			clean_line = fasta_file.gets.strip
			if clean_line.length > 0

				if clean_line[0] == ">"

					if is_first_header
						is_first_header = false
					else
						# process current sequence
						tmp_sequence = Hash.new ()
						tmp_sequence[:num_sequence] = num_sequence
						tmp_sequence[:header] = tmp_header
						tmp_sequence[:content] = tmp_content
						
						if process_sequence(tmp_sequence, parameters)
							write_sequence(tmp_sequence, file_output)
						end
						tmp_sequence = nil

					end

					num_sequence += 1
					tmp_header = clean_line
					tmp_content = ""

				elsif /[a-zA-Z]/ =~ clean_line[0]
					tmp_content = tmp_content << clean_line
				end
			end
		end

		# process last sequence
		tmp_sequence = Hash.new ()
		tmp_sequence[:num_sequence] = num_sequence
		tmp_sequence[:header] = tmp_header
		tmp_sequence[:content] = tmp_content
		if process_sequence(tmp_sequence, parameters)
			write_sequence(tmp_sequence, file_output)
		end
		tmp_sequence = nil

	end
end


# the program continues to open the file, writes one sequence to it and
# closes it. This is done to avoid having in memory a very large string that
# contains sequences already processed. The problem in doing so is relative
# to the file opening time, but this should not be a huge problem
def write_sequence(sequence, filepath_output)

	tmp_string = sequence[:header] + "\n"
	tmp_string = tmp_string << sequence[:content].scan(/.{1,80}/m).join("\n")

	if filepath_output != nil

		File.open(filepath_output, "a") do |file_output|
			file_output << tmp_string
			file_output << "\n\n"
		end
	else
		puts tmp_string
	end
	tmp_string =  nil

end


# main program ################################################################
begin
	
	parameters = process_parameters(ARGV)
	# if -h flag is set, display program help and quit the program
	if parameters[:help] == true
		show_help
		exit
	end

	if parameters[:file_path] == nil
		raise InvalidParameter.new("No input file given")
	end

	# creates an empty file (or flushes it if already exists)
	if parameters[:file_output] != nil
		File.open(parameters[:file_output], 'w') {}
	end

	out_sequences = sequences_selector(parameters[:file_path], parameters, parameters[:file_output])

rescue InvalidParameter => e
	puts e
end
