#!/usr/bin/env -S ruby --disable=gems -w
# Written by Sourav Goswami - https://github.com/Souravgoswami/
# GNU General Public License v3.0
# Version 4.0

require 'io/console'
require 'zlib'
require 'json'

STDOUT.sync, STDIN.sync = true, true

Default_Path = "#{__dir__}/words.json.gz"
# Default_Path = "/usr/share/jmblr/words.json.gz"

Colour1, Colour2, Colour3, Colour4, Colour5 = 40..45, 208..213, 214..219, 196..201, 214..219
path = nil

word_arg = ARGV.select { |arg| arg.start_with?('--words=') || arg.start_with?('-w=') }.each { |arg| ARGV.delete(arg) }

unless word_arg.empty?
	word_arg = word_arg[-1].split(?=)[1]
	path = word_arg if File.exist?(word_arg) unless word_arg.nil?
end

path = Default_Path unless path

colour_switch = if ARGV.include?('--no-colour') || ARGV.include?('-nc')
	ARGV.delete('--no-colour')
	ARGV.delete('-nc')
	1
else
	0
end

colourize = ->string='Ruby', colour=Colour1 do
	enable_colours = colour_switch % 2 == 0 ? true : false
	colour = colour.to_a if colour.is_a?(Range) || colour.is_a?(Enumerator)
	arr_size = colour.size

	string.each_line do |str|
		index, div = 0, str.length / colour.size

		str.length.times do |i|
			index += 1 if i % div == 0 unless (i < 1 || index >= arr_size - 1 || colour.length > str.length || str[i] == ' '.freeze)
			print "\033[38;5;#{colour[index]}m#{str[i]}" if enable_colours
			print string[i] unless enable_colours
		end

		print("\e[0m".freeze)
	end

	nil
end

if ARGV.to_a.include?('-h') or ARGV.include?('--help')
	colourize.call <<~EOF, [Colour2, Colour2.reverse_each, Colour1].sample
		Hi my name is Jumbler! Also known as jmblr...
		I am a small program to whom you give jumbled up word(s), and get matching words.

			Arguments:
			--help			-h	Show this help message.
			--no-colour		-nc	Add no colours to the output.
			--update		-u	Download missing dictionary from the internet.
								(update if available)
			--words=		-w=	Specify the wordlist that will be used for searching.
							(The word file has to be in plain text ASCII format)
			--random		-r		Show a random word
							(type -rr or --randomr for 2 words)
							(-rrr or --randomrr for 3 words and so on)
			--as-text		-t	Show textual message format
			--file= 		-f=	Read file and format as textual message

		Useful keys while live searching (running #{__FILE__} without an argument or redirection):
			backspace		Delete the last character.
			ctrl + d/ctrl + b	Clear everything you typed.
			ctrl + x/ctrl+q		Exit.
			ctrl + r		Refresh the screen.
			ctrl + c		Toggle colours.
	EOF


print ?\n.freeze * 2
exit 0
end

update = -> do
	begin
		colourize.call("Update the database? (N/y): ")
		exit 0 unless STDIN.gets.chomp.downcase.start_with?('y')

		require 'net/http'
		puts colourize.call("Downloading data from #{site}")

		site = "https://raw.githubusercontent.com/Souravgoswami/jmblr/master/words.json.gz"
		data = Net::HTTP.get(URI("#{site}")).tap(&:strip!)
		unless data == '404: Not Found'
			puts colourize.call("Writing #{(data.chars.size/1000000.0).round(2)} MB to #{path}. Please Wait a Moment", Colour2)

			begin
				Dir.mkdir(path.split('/')[0..-2].join('/')) unless File.exist?(path.split('/')[0..-2].join('/'))
				IO.write(path, data)

			rescue Errno::ENOENT
				puts colourize.call("Directory doesn't exist. Please create a directory #{path.split('/')[0..-2].join('/')}/", Colour4)
				puts colourize.call("The file I am trying write to is: #{path}", Colour4)
				exit 126

			rescue Errno::EACCES
				puts colourize.call("To write to #{path}, you need root privilege...", Colour4)
				exit 126

			rescue SocketError
				puts colourize.('Make sure you have an active internet connection', Colour4.reverse_each)
				puts colourize.('Retry? (N/y)', Colour4)
				retry if  gets.chomp.downcase == ?y
				exit! 126
			end

			puts colourize.call("All done! The file has been saved to #{path}. Run #{__FILE__} to begin solving puzzles!", Colour5)
			exit 0
		else
			colourize.call 'Uh Oh! The update is not successful. If the problem persists, please contact the developer: <souravgoswami@protonmail.com>'
			exit 126
		end

	rescue Exception
		puts colourize.('Something went wrong!')
		exit 127
	end
	exit 0
end

unless File.readable?(path)
	puts colourize.call File.exist?(path) ? "The #{path} file is not readable! How can I read my words? :(" : "The #{path} file doesn't exist. Where are my words? :'("
	puts colourize.call("Please run #{__FILE__} --update or #{__FILE__} -u to download the wordlist")
	puts colourize.call("You can mention the path with --words=path or -w=path option")
	puts colourize.call("Run #{__FILE__} --help or #{__FILE__} -h for more details")
	puts colourize.call('However, you can run the update now. Do you want that?(Y/n)')
	exit! 120 if STDIN.gets.strip.downcase == ?n
	update.call
end

Terminal_Height, Terminal_Width = STDOUT.tty? ? STDOUT.winsize : [20, 50]
update.call if ARGV.include?('-u') or ARGV.include?('--update')

message = ['Please Wait a Moment, Initializing the Dictionary', 'Umm...Just a couple of seconds please...',
				'Hi there! Please wait a moment while I initialize the dictionary...'].sample

t = Thread.new { '|/-\\'.freeze.each_char { |c| print " \e[2K#{c} #{message}\r" || sleep(0.01) } while true }

$emp = ''.freeze

inflated_data = Zlib::GzipReader.open(path).read
data = JSON.parse(inflated_data)
sorted_data, question_words = data['anagrams'], data['questions']

search_word = ->(w) { sorted_data[w.strip.downcase.chars.sort.join].to_a.tap(&:uniq!) }

t.kill
puts

unless STDIN.tty?
	STDIN.read.split.each do |text|
		txt = text.tap(&:strip!).tap(&:downcase!)
		puts colourize.call("Possible matches for '#{txt}': ", Colour2.reverse_each)
		puts search_word === txt
		puts colourize.call(?=.freeze * Terminal_Width, Colour2.reverse_each)
	end

	exit if ARGV.empty?
end

if ARGV.select { |arg| arg.start_with?('--random') || arg.start_with?('-r') }.any?
	ARGV.select { |arg| arg.start_with?('-r') || arg.start_with?('--random') }.join.count(?r).times do
		puts colourize === 'Generating a Random Word!'
		wrd = question_words.sample until question_words.count(wrd) > 3
		word = wrd.chars.shuffle!.join
		puts colourize.("Possible matches for '#{word}': ", Colour2.reverse_each)
		puts search_word.(word), ?\n
	end
		ARGV.each { |arg| ARGV.delete(arg) if arg.start_with?('--random') || arg.start_with?('-r') }
	exit! 0 if ARGV.empty?
end

if ARGV.include?('--as-message') || ARGV.include?('-t')
	ARGV.delete('--as-message')
	ARGV.delete('-t')

	ARGV.join(' ').split(' ').each do |text|
		downcased_chars = {}

		txt = text.strip.chars.map.with_index { |x, i|
			downcased = x.downcase
			if downcased == x
				x
			else
				downcased_chars[i] = x
				downcased
			end
		}.join

		m = txt.scan(/[a-z]/).join
		ret1, ret2 = '', ''

		txt.chars.each_with_index { |x, i|
			was_downcased = downcased_chars[i]
			if was_downcased
				ret1 << was_downcased
			else
				ret1 << x
			end
		}

		matches = search_word.call(m) | [m]

		if matches
			temp = matches[0]
			orig_index = matches.index(m)
			matches[0] = m
			matches[orig_index] = temp
		end

		print_fmt = if matches && matches.count > 2
			"#{ret1} (#{matches.shift}: #{matches.join(', ')})#{ret2} "
		elsif matches && matches.count > 1
			"#{ret1} (#{matches.join(', ')}) "
		else
			"#{ret1}#{ret2} "
		end

		print print_fmt
	end

	puts
	exit
end

# Read file if filename given
arg_file = ARGV.reverse.find { |x| x[/\A\-(\-file|f)\=.+\z/] }

if arg_file
	ARGV.delete(arg_file)
	filename = arg_file.partition(?=)[2]

	abort %Q(File "#{filename}" is not readable) unless File.readable?(filename)

	begin
		file_data = IO.foreach(filename)

		# Colours
		highlight_single_match = colour_switch == 0 ? "\e[34;1m" : ''
		highlight_multiple_matches = colour_switch == 0 ? "\e[33;1m" : ''
		highlight_reset = colour_switch == 0 ? "\e[0m" : ''

		file_data.each do |line|
			next unless line.valid_encoding?

			line.split(' '.freeze).each do |text|
				downcased_chars = {}

				txt = text.strip.chars.map.with_index { |x, i|
					downcased = x.downcase
					if downcased == x
						x
					else
						downcased_chars[i] = x
						downcased
					end
				}.join

				m = txt.scan(/[a-z]/).join
				ret1, ret2 = '', ''

				txt.chars.each_with_index { |x, i|
					was_downcased = downcased_chars[i]
					if was_downcased
						ret1 << was_downcased
					else
						ret1 << x
					end
				}

				matches = search_word.call(m) | [m]

				if matches
					temp = matches[0]
					orig_index = matches.index(m)
					matches[0] = m
					matches[orig_index] = temp
				end

				print_fmt = if matches && matches.count > 2
					"#{ret1} (#{highlight_multiple_matches}#{matches.shift}: #{matches.join(', ')}#{highlight_reset})#{ret2} "
				elsif matches && matches.count > 1
					"#{ret1} (#{highlight_single_match}#{matches.join(', ')})#{highlight_reset} "
				else
					"#{ret1}#{ret2} "
				end

				print print_fmt
			end

			puts
		end
	rescue Interrupt, SignalException
	rescue StandardError
		puts $!
		exit
	end

	puts
	exit
end

unless ARGV.empty?
	ARGV.each do |text|
		txt = text.strip.downcase
		puts colourize.("Possible matches for '#{txt}': ", Colour2.reverse_each)
		puts search_word.(txt)
		colourize.call(?=.freeze * Terminal_Width, Colour2.reverse_each)
	end
else
	print("\e[2J\e[H\e[3J")
	colourize.call('Type Something!', Colour5)
	rndwrd, c, search, inp = question_words.sample, '', '', '', ''

	while true
		begin
			c = inp = STDIN.getch.force_encoding('ascii'.freeze)
			puts || exit(0) if [?\e.freeze, ?\u0011.freeze, ?\u0018.freeze].include?(c)

			if c == ?\r.freeze then c.replace($emp)
			elsif c == ?\u007F.freeze then search.chop!
			elsif c == ?\u0004.freeze || c == ?\u0002.freeze then search.clear
			elsif c == ?\u0003.freeze then colour_switch += 1
			else search << c.downcase if c[/^[a-z\s\d+]+$/]
			end

			print("\e[H\e[J".freeze)
			puts colourize.(?= * Terminal_Width)

			if search.empty?
				print "\e[5m".freeze
				colourize.call(['Type a jumble word!', 'Type a word', 'Press esc when you are done!'].sample)
				print "\033[0m\n\n".freeze
				colourize.call(?=.freeze * Terminal_Width)
			else
				puts colourize.call("Possible matches for '#{search}': ", Colour2.reverse_each)
				puts search_word.(search)
				colourize.(?=.freeze * Terminal_Width, Colour1.reverse_each)
			end

			puts
			colourize.call("Search For: #{search}", Colour2)
			print(?\n.freeze * (Terminal_Height.to_i / 3))

			rndwrd = question_words.sample.to_s.chars.shuffle.join if search.empty? && rndwrd != search && inp != ?\u0004.freeze
			colourize.("A fun challenge for you, can you solve #{rndwrd} ?", Colour3)

		rescue StandardError
			puts $!.full_message
			exit! 128
		end
	end
end
