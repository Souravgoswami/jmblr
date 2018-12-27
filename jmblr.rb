#!/usr/bin/ruby -W0
# Written by Sourav Goswami - https://github.com/Souravgoswami/
# GNU General Public License v3.0
# Version 1.5

require 'io/console'
STDOUT.sync, STDIN.sync = true, true

# TODO: Set the default path if the source code is running
Default_Path = "#{File.dirname(__FILE__)}/words"

# TODO:  for debian package, and arch package
# Default_Path = "/usr/share/jmblr/words"

# Let's declare the colour so the range will not be created everytime
Colour1 = 40..45
Colour2 = 208..213
Colour3 = 214..219
Colour4 = 196..201
Colour5 = 214..219

path = nil

word_arg = ARGV.select { |arg| arg.start_with?('--words=') || arg.start_with?('-w=') }
word_arg.each { |arg| ARGV.delete(arg) }

unless word_arg.empty?
	word_arg = word_arg[-1].split('=')[1]
	unless word_arg.nil?
		path = word_arg if File.exist?(word_arg)
	end
end

path = Default_Path if path.nil?

colour_switch = 0
if ARGV.include?('--no-colour') || ARGV.include?('-nc')
	ARGV.delete('--no-colour')
	ARGV.delete('-nc')
	colour_switch = 1
end

colourize = ->(string='Ruby', colour=Colour1) do
	enable_colours = colour_switch % 2 == 0 ? true : false
	colour = colour.to_a if colour.is_a?(Range) || colour.is_a?(Enumerator)
	arr_size = colour.size

	string.each_line do |str|
		print "\033[0m"
		index, div = 0, str.length/colour.size

		str.length.times do |i|
			index += 1 if i % div == 0 unless (i == 0 || i == 1 || index >= arr_size - 1 || colour.length > str.length || str[i] == ' ')

			print "\033[38;5;#{colour[index]}m#{str[i]}" if enable_colours
			print string[i] unless enable_colours
		end
	end
end

if ARGV.to_a.include?('-h') or ARGV.include?('--help')
colourize.call(
"Hi my name is Jumbler! Also known as jmblr...
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

	Useful keys while live searching (running #{__FILE__} without an option or redirection):
		backspace		Delete the last character.
		ctrl + d/ctrl + b	Clear everything you typed.
		ctrl + x/ctrl+q		Exit.
		ctrl + r		Refresh the screen.
		ctrl + c		Toggle colours.", [Colour2, Colour2.reverse_each, Colour1].sample)

puts "\n" * 2
exit! 0
end

update = -> do
	begin
		colourize.call("Update the database? (N/y): ")
		exit! 0 unless STDIN.gets.chomp.downcase.start_with?('y')

		require 'net/http'
		site = "https://raw.githubusercontent.com/Souravgoswami/jmblr/master/words"

		colourize.call("Downloading data from #{site}")
		puts

		data = Net::HTTP.get(URI("#{site}"))
		unless data.chomp == '404: Not Found'
			colourize.call("Writing #{(data.chars.size/1000000.0).round(2)} MB to #{path}. Please Wait a Moment", Colour2)
			puts

			begin
				unless File.exist?(path.split('/')[0..-2].join('/'))
					Dir.mkdir(path.split('/')[0..-2].join('/'))
				end

				File.open(path, 'w+') { |file| file.write(data) }

			rescue Errno::ENOENT
				colourize.call("Directory doesn't exist. Please create a directory #{path.split('/')[0..-2].join('/')}/", Colour4)
				puts

				colourize.call("The file I am trying write to is: #{path}", Colour4)
				puts
				exit! 126

			rescue Errno::EACCES
				colourize.call("To write to #{path}, you need root privilege...", Colour4)
				puts
				exit! 126

			rescue SocketError
				colourize.call('Make sure you have an active internet connection', Colour4.reverse_each)
				puts

				colourize.call('Retry? (N/y)', Colour4)
				puts

				retry if  gets.chomp.downcase == 'y'
				exit! 126
			end

			colourize.call("All done! The file has been saved to #{path}. Run #{__FILE__} to begin solving puzzles!", Colour5)
			puts
			exit! 0
		else
			colourize.call 'Uh Oh! The update is not successful. If the problem persists, please contact the developer: <souravgoswami@protonmail.com>'
			exit! 126
		end

	rescue Exception => error
		colourize.call('Something went wrong.')
		puts

		colourize.call('If the problem persists, then please contact the developer')
		puts

		colourize.call('Email: <souravgoswami@protonmail.com>')
		puts

		colourize.call("Inform the developer about \"#{error}\"")
		puts "\n"

		colourize.call(error.backtrace.join("\n"))
		puts

		exit! 127
	end
	exit! 0
end

unless File.readable?(path)
	colourize.call File.exist?(path) ? "The #{path} file is not readable! How can I read my words? :(" : "The #{path} file doesn't exist. Where are my words? :'("
	puts

	colourize.call("Please run #{__FILE__} --update or #{__FILE__} -u to download the wordlist")
	puts

	colourize.call("You can mention the path with --words=path or -w=path option")
	puts

	colourize.call("Run #{__FILE__} --help or #{__FILE__} -h for more details")
	puts

	colourize.call('However, you can run the update now. Do you want that?(Y/n)')
	puts

	exit! 120 if gets.chomp.downcase == 'n'
	update.call
end

# exit if no tty found
begin
	Terminal_Width, Terminal_Height = STDOUT.winsize[1], STDOUT.winsize[0]

rescue Errno::ENOTTY
	colourize.call "The window size can't be determined. Are you running me in a terminal?"
	puts
	exit! 2
end

update.call if ARGV.include?('-u') or ARGV.include?('--update')

$status = nil

colourize.call(['Please Wait a Moment, Initializing the Dictionary', 'Umm...Just a couple of seconds please...',
				'Hi there! Please wait a moment while I initialize the dictionary...'].sample)
puts

Thread.new do
		loop do
		'|/-\\'.each_char do |c|
			colourize.call("#{c}\r") ; sleep 0.03 ;
			break if $status
		end
		break if $status
	end
end

unsorted = File.readlines(path).map(&:strip).map(&:downcase).reject { |i| i =~ /[^a-z]/}.uniq
sortedwords = unsorted.map { |ch| ch.chars.sort.join }
unsorted_size = unsorted.size

search_word = ->(word) do
		word = word.strip.downcase.chars.sort.join
		unsorted_size.times { |i| puts unsorted[i] if sortedwords[i] == word }
end

filter = ->(text='') do
	text = text.strip.downcase
	unneeded = text.scan(/[^a-z]/).join
	text.delete(unneeded)
end

$status = 1

pipe, texts = nil, ''
require 'timeout'
begin
	Timeout::timeout(0.00000000000000000000001) { pipe = STDIN.gets }
rescue Exception
end

if pipe
	texts += pipe

	loop do
		val = STDIN.gets
		break if val.nil?
		texts += val
	end

	texts.split.each do |text|
		txt = filter.call(text)
		colourize.call("Possible matches for '#{txt}': ", Colour2.reverse_each)
		puts "\n" * 2
		search_word.call(txt)
		colourize.call("=" * Terminal_Width, Colour2.reverse_each)
	end
	exit if ARGV.empty?
end

if ARGV.select { |arg| arg.start_with?('--random') || arg.start_with?('-r') }.any?
	ARGV.select { |arg| arg.start_with?('-r') || arg.start_with?('--random') }.join.count('r').times do
		word = File.readlines(path).sample.strip.downcase.chars.shuffle.join
		colourize.call("Possible matches for '#{word}': ", Colour2.reverse_each)
		puts
		search_word.call(word)
		puts
	end
		ARGV.each { |arg| ARGV.delete(arg) if arg.start_with?('--random') || arg.start_with?('-r') }
	exit! 0 if ARGV.empty?
end

unless ARGV.empty?
	ARGV.each do |text|
		txt = filter.call(text)

		colourize.call("Possible matches for '#{txt}': ", Colour2.reverse_each)
		puts "\n" * 2

		search_word.call(txt)
		colourize.call("=" * Terminal_Width, Colour2.reverse_each)
	end
else
	print("\033[H\033[J")
	colourize.call('Type Something!', Colour5)
	rndwrd, c, w, search = sortedwords.sample, '', '', '', ''
	inp = ''
	loop do
		begin
			c = inp = STDIN.getch
			print("\033[H\033[J")

			exit! 0 if ["\e", "\u0011", "\u0018"].include?(c)

			if c == "\r" then c = ''
				elsif c == "\u007F" then search.chop! unless search.empty? ; w = search
				elsif c == "\u0004" || c == "\u0002" then search, w = '', ''
				elsif c == "\u0003" then colour_switch += 1
			else
				w += c
				search += c.downcase if c =~ /^[a-z\s\d+]+$/
			end

			print("\033[H\033[J")
			colourize.call("=" * Terminal_Width)
			puts

			if search.empty?
				print "\033[05m"
				colourize.call(['Type a jumble word!', 'Type a word', 'Press esc when you are done!'].sample)
				puts "\033[0m"
				print "\n" * 2
				colourize.call("=" * Terminal_Width)
			else
				colourize.call("Possible matches for '#{search}': ", Colour2.reverse_each)
				print "\n" * 2
				search_word.call(search)
				colourize.call("=" * Terminal_Width, Colour1.reverse_each)
			end


			colourize.call("Search For: #{search}", Colour2)
			print("\n" * (Terminal_Height.to_i/3))

			rndwrd = sortedwords.sample.chars.shuffle.join if search.empty? && rndwrd != search && inp != "\u0004"
			colourize.call("A fun challenge for you, can you solve #{rndwrd} ?", Colour3)
		rescue Exception
			exit! 128
		end
	end
end
