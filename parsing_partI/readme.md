EMBL to FASTA parser
--------------------

An EMBL to FASTA file parser done as a course exercise.
Extracts from the EMBL file:

1. the AC code
2. the length of the sequence
3. the organism whose sequence is refferred to
4. the description
5. the sequence

__If__ the sequence is about the mRNA:

6. the start and end of the coding sequence
7. wheter the are the start {atg} and end {taa | tga | tag} codons
8. the coding sequence from the start index to the end index
