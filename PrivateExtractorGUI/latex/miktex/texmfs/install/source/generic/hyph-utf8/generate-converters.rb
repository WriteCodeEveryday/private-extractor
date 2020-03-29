#!/usr/bin/env ruby

require_relative 'hyph-utf8'

$path_root=File.expand_path("../../../..", __FILE__)
$encoding_data_dir = File.expand_path("../data/encodings", __FILE__)
$output_data_dir = "#{$path_root}/tex/generic/hyph-utf8/conversions"

def output_file_name(encoding)
	File.join($output_data_dir, sprintf('conv-utf8-%s.tex', encoding))
end

$header = <<__EOHEADER__
%% conv-utf8-%s.tex
%%
%% Conversion from UTF-8 to %s,
%% used before loading hyphenation patterns for 8-bit TeX engines.
%%
%% This file is part of hyph-utf8 package and autogenerated.
%% See http://tug.org/tex-hyphen
%%
%% Copyright 2008-%d TeX Users Group.
%% You may freely use, modify and/or distribute this file.
%% (But consider adapting the scripts if you need modifications.)
__EOHEADER__

def output_copyright_notice(outfile, encoding)
	outfile.printf $header, encoding, encoding.upcase, Time.new.year
end

$uniconvmacro1 = <<__EOUNIMAC1__
% macros adapted from ConTeXt MKII; see unic-ini.mkii
\\def\\unicodechar#1{%
	\\ifcsname unichar@\\number#1\\endcsname
	  \\csname unichar@\\number#1\\endcsname
	\\else
	  \\errmessage{Unicode character [#1] not in encoding.}%
	\\fi}
__EOUNIMAC1__

$uniconvmacros = [nil, nil]

$uniconvmacros << <<__EOTWOBYTES__
\\def\\utftwouniglyph#1#2%
	{\\expandafter\\unicodechar\\expandafter
		{\\the\\numexpr64*(#1-192)+`#2-128\\relax}}
__EOTWOBYTES__

$uniconvmacros << <<__EOTHREEBYTES__
\\def\\utfthreeuniglyph#1#2#3%
	{\\expandafter\\unicodechar\\expandafter
		{\\the\\numexpr4096*(#1-224)+64*(`#2-128)+`#3-128\\relax}}
__EOTHREEBYTES__

$uniconvmacros << <<__EOFOURBYTES__
\\def\\utffouruniglyph#1#2#3#4%
	{\\expandafter\\unicodechar\\expandafter
		{\\the\\numexpr262144*(#1-240)+4096*(`#2-128)+64*(`#3-128)+`#4-128\\relax}}
__EOFOURBYTES__

$uniconvmacro2 = <<__EOUNIMAC2__

\\def\\addunichar #1 #2 {\\expandafter\\def\\csname unichar@\\number#1\\endcsname{#2}}

% \\addunichar "unicode_code - ^^font_encoding_code
__EOUNIMAC2__

["t8m", "lth"].each do |encoding|
	# load encoding
	e = HyphEncoding.new(encoding)

	# open file
	File.open(output_file_name(encoding), "w") do |file_out|

		# copyright notice
		output_copyright_notice(file_out, encoding)
		file_out.puts

		# macro to get mapping unicode -> font encoding & error message if screwed up
		file_out.puts $uniconvmacro1

		# minimal and maximal length of characters in the encoding (until now just 2 & 3)
		unicode_characters_array = e.unicode_characters.sort
		length_min = unicode_characters_array.first[1].bytes.size
		length_max = unicode_characters_array.last[1].bytes.size

		# only output the necessary macros for transforming UTF-8 -> Unicode number
		(length_min..length_max).each do |nbytes|
			file_out.puts $uniconvmacros[nbytes]
		end

		# macro to store mapping unicode -> font encoding
		file_out.puts $uniconvmacro2

		# all unicode characters in the encoding
		e.unicode_characters.sort.each do |code,c|
			file_out.printf("\\addunichar \"%04X ^^%02x \\lccode\"%02X=\"%02X %% %s - %s\n",
				c.code_uni, c.code_enc, c.code_enc, c.code_enc, [c.code_uni].pack('U'), c.name)
		end
		file_out.puts

		# make all the possible first characters active
		# output the definition into file
		e.unicode_characters_first_byte.sort.each do |first_byte_code,chars|
			byte = first_byte_code.hex
			size = chars[0].bytes.size
			# 2-byte: 0b11000000 <= byte < 0b11100000
			str = case size
			when 2 then
				"two"
			# 3-byte: 0b11100000 <= byte < 0b11110000
			when 3 then
				"three"
			# 4-byte: 0b11110000 <= byte < 0b11111000
			when 4 then
				"four"
			end
			file_out.printf("\\catcode\"%02X=\\active \\def^^%02x{\\utf%suniglyph{\"%02X}}\n", byte, byte, str, byte)
		end
	end
end

["ec", "qx", "t2a", "lmc", "il2", "il3", "l7x"].each do |encoding|
	# load encoding
	e = HyphEncoding.new(encoding)

	# open file
	File.open(output_file_name(encoding), "w") do |file_out|

		# copyright notice
		output_copyright_notice(file_out, encoding)
		file_out.puts '%'

		e.unicode_characters_first_byte.sort.each do |first_byte_code,chars|
			# sorting all the second characters alphabetically
			chars.sort!{|x,y| x.code_uni <=> y.code_uni }
			# make all the possible first characters active
			# output the definition into file
			file_out.printf("\\catcode\"%02X=\\active\n", first_byte_code.hex)
		end
		file_out.puts "%"
		e.unicode_characters_first_byte.sort.each do |first_byte_code,chars|
			first_byte_code = first_byte_code.hex
			size = chars[0].bytes.size
			if size != 2 then
				throw "The encoding #{encoding} uses more than two bytes to encode characters"
			else

				file_out.printf("\\def^^%02x#1{%%\n", first_byte_code)
				string_fi = ""
				for i in 1..(chars.size)
					uni_character = chars[i-1]
					enc_byte    = uni_character.code_enc
					enc_byte    = [ uni_character.code_enc ].pack('c').unpack('H2')
					file_out.printf("\t\\ifx#1^^%02x^^%02x\\else %% %s - U+%04X - %s\n", uni_character.bytes[1], uni_character.code_enc, [uni_character.code_uni].pack('U'), uni_character.code_uni, uni_character.name)
					string_fi = string_fi + "\\fi"
				end

			# at least three bytes
			end
			file_out.puts "\t\\errmessage{Hyphenation pattern file corrupted or #{encoding} encoding not supported!}"
			file_out.puts string_fi + "}"
		end
		file_out.puts '%'
		file_out.puts '% ensure all the chars above have valid \lccode values'
		file_out.puts '%'
		e.lowercase_characters.each do |character|
			code = [ character.code_enc ].pack("c").unpack("H2").first.upcase
			# \lccode"FF="FF
			file_out.printf "\\lccode\"%s=\"%s %% %s - U+%04X - %s\n", code, code, [character.code_uni].pack('U'), character.code_uni, character.name
		end

		file_out.puts
	end
end


