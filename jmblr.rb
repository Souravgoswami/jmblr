#!/usr/bin/env ruby -w
# Written by Sourav Goswami - https://github.com/Souravgoswami/
# Version 1.3
# GNU General Public License v3.0

require 'io/console'
STDOUT.sync, STDIN.sync = true, true

# TODO: Set the default path if the source code is running
# Default_Path = "#{Dir.pwd}/words"

# TODO:  for debian package, and arch package
Default_Path = "/usr/share/jmblr/words"

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

colourize = ->(string='Ruby', colour=(40..45), linebreak=false) {
	enable_colours = colour_switch % 2 == 0 ? true : false
	colour = colour.to_a if colour.is_a?(Range) || colour.is_a?(Enumerator)
	arr_size = colour.size

	string.split("\n").each do |str|
		print "\033[0m"
		index, div = 0, str.length/colour.size

		str.length.times do |i|
			index += 1 if i % div == 0 unless (i == 0 || i == 1 || index >= arr_size - 1 || colour.length > str.length || str[i] == ' ')

			print "\033[38;5;#{colour[index]}m#{str[i]}" if enable_colours
			print string[i] unless enable_colours
		end
		puts if linebreak
	end
}

update = -> {
	begin
		colourize.call("Update the database? (N/y): ")
		exit! 0 unless STDIN.gets.chomp.downcase.start_with?('y')

		require 'net/http'
		site = "https://raw.githubusercontent.com/Souravgoswami/jmblr/master/words"

		colourize.call("Downloading data from #{site}")
		puts

		data = Net::HTTP.get(URI("#{site}"))
		unless data.chomp == '404: Not Found'
			colourize.call("Writing #{(data.chars.size/1000000.0).round(2)} MB to #{path}. Please Wait a Moment", 208..213, true)

			begin
				unless File.exist?(path.split('/')[0..-2].join('/'))
					Dir.mkdir(path.split('/')[0..-2].join('/'))
				end

				File.open(path, 'w+') { |file| file.write(data) }

			rescue Errno::ENOENT
				colourize.call("Directory doesn't exist. Please create a directory #{path.split('/')[0..-2].join('/')}/", 196..201, true)
				colourize.call("The file I am trying write to is: #{path}", 196..201, true)

				exit! 126

			rescue Errno::EACCES
				colourize.call("To write to #{path}, you need root privilege...", 196..201, true)
				exit! 126

			rescue SocketError
				colourize.call('Make sure you have an active internet connection', (196..201).reverse_each, true)
				colourize.call('Retry? (N/y)', 196..201, true)
				retry if  gets.chomp.downcase == 'y'
				exit! 126
			end

			colourize.call("All done! The file has been saved to #{path}. Run #{__FILE__} to begin solving puzzles!", 214..219, true)
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
}

unless File.exist?(path)
	colourize.call("The #{path} file doesn't exist...")
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
unless STDOUT.tty?
	colourize.call('Please make sure to run me in a terminal')
	colourize.call('Terminal like deepin-terminal, gnome-terminal, konsole, terminator, terminix,
terminology, xfce4-terminal, xterm and others...')
	exit! 125
end

STDOUT.sync, STDIN.sync = true, true
if ARGV.include?('-h') or ARGV.include?('--help')
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

	Examples:
		1. echo altering bob voles ybur | #{__FILE__}

		2. #{__FILE__} triangel bob loevs ruyb

		3. cat a_file.txt | #{__FILE__}

		4. All of the above with --no-colour or -nc to eliminate colours.

		5. All the above exampleswith --words=path_to_wordlist or -w=path_to_wordlist

			Example 1 (assuming you have a british wordlist in /usr/share/dict/):
				echo triangle bob | #{__FILE__} --words=/usr/share/dict/british

			Example 2 (assuming that you have downloaded a wordlist in txt format):
				echo triagnle | #{__FILE__} -w=/home/user/Downloads/worlist.txt

	Useful keys while live searching (running #{__FILE__} without an option or redirection):
		backspace		Delete the last character.
		ctrl + d/ctrl + b	Clear everything you typed.
		ctrl + x/ctrl+q		Exit.
		ctrl + r		Refresh the screen.
		ctrl + c		Toggle colours.

", 40..45, true)
puts
exit! 0
end unless ARGV[0].nil?

if ARGV.include?('-u') or ARGV.include?('--update')
	update.call
end

$status = nil

colourize.call(['Please Wait a Moment, Initializing the Dictionary', 'Umm...Just a couple of seconds please...',
				'Hi there! Please wait a moment while I initialize the dictionary...'].sample)

Thread.new {
		loop do
			'|/-\\'.each_char do |c|
				colourize.call("#{c}\r") ; sleep 0.03 ;
				break if $status
			end
			break if $status
	end
}
puts

unsorted = File.open(path).readlines.map(&:chomp).map(&:downcase).select { |i| i =~ /^[a-z]+$/}.uniq
sortedwords = unsorted.map do |ch| ch.split('').sort.join end
unsorted_size = unsorted.size

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

	texts.split(' ').each do |text|
		w = text.downcase.split('').sort.join
		colourize.call("Looking for #{text} in the dictionary")
		puts "\n" * 2

		unsorted_size.times { |i| puts unsorted[i] if sortedwords[i] == w }

		colourize.call("=" * %x(tput cols).to_i, [(40..45), (40..45).reverse_each].sample)
	end
	exit if ARGV.empty?
end

unless ARGV.empty?
	ARGV.each do |text|
		colourize.call("Looking for #{text} in the dictionary")
		puts "\n" * 2

		w = text.downcase.split('').sort.join

		unsorted_size.times { |i| puts unsorted[i] if sortedwords[i] == w }

		colourize.call("=" * %x(tput cols).to_i, [(40..45), (40..45).reverse_each].sample)
	end
else
	print("\033[H\033[J")
	colourize.call(['Hi! Give me jumbled words!', 'Type me some words', 'Alright... Ready?'].sample, 196..200)
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
				else w += c ; search += c end

			print("\033[H\033[J")
			colourize.call("=" * %x(tput cols).to_i)
			puts

			if search.empty?
				print "\033[05m"
				colourize.call(['Type a jumble word!', 'Type a word', 'Press esc when you are done!'].sample)
				puts "\033[0m"
			else
				colourize.call("Possible Matches for #{search}:", (208..213).reverse_each, true)
			end

			colourize.call("=" * %x(tput cols).to_i, (40..45).reverse_each)
			puts

			w = w.downcase.split('').sort.join
			unsorted_size.times { |i| puts unsorted[i] if sortedwords[i] == w }

			rndwrd = sortedwords.sample if search.empty? && rndwrd != search && inp != "\u0004" && inp != "\u00012"

			colourize.call("=" * %x(tput cols).to_i)
			colourize.call("Search For: #{search}", 208..213)

			print("\n" * (%x(tput lines).to_i/3))

			colourize.call("A fun challenge for you, can you solve #{rndwrd}" + "?", (214..219).reverse_each)
		rescue Exception
			exit! 128
		end
	end
end
