#!/usr/bin/env ruby -W0
# Written by Sourav Goswami - https://github.com/Souravgoswami/
# GNU General Public License v3.0

require 'io/console'
STDOUT.sync, STDIN.sync = true, true
if ARGV.include?('-h') or ARGV.include?('--help')
puts <<EOF
Hi my name is Jumbler! Also known as jmblr...
I am a small program where you will give me a jumpled up word(s), and I try to solve that with my tiny brain.

What job can I accomplish?
	-> When you run me, I will ask you to type your word. I will show my calculation in real time.
	- Sorry if I take some time to solve your jumbled up word - I still have to do all my calculations.
	- But I will try my best to solve the word as fast as possible. Probably some milliseconds...
	-> Remember to press the escape key when you want to leave!

	-> You can pass me some command line arguments as well!
	-> I will accept one or more than one word as argument. I will solve them one by one.
	-> I will not show any result if I don't get something meaningful from your jumbled word(s).

Arguments:
	--help		-h		Show this help message.

	--update	-u		Download missing dictionary from the internet(update if available)
				(Note that if the application is working, there's no need to update the database).
EOF
exit! 0
end unless ARGV[0].nil?

Red, Green, Blue, Pink, Blink, Reset = "\033[1;31m", "\033[1;32m", "\033[1;34m", "\033[1;35m", "\033[05m", "\033[0m"

if ARGV.include?('-u') or ARGV.include?('--update')
	begin
		print "#{Pink}Update the database? [#{Blink}#{Green}N#{Pink}/#{Red}y#{Reset}#{Pink}]: #{Blue}"
		require 'net/http'
		exit! 0 unless STDIN.gets.chomp.downcase.start_with?('y')
		puts "#{Green}Downloading data from #{Pink}https://raw.githubusercontent.com/Souravgoswami/jmblr/master/words#{Reset}"
		data = Net::HTTP.get(URI('https://raw.githubusercontent.com/Souravgoswami/jmblr/master/words'))
		unless data.chomp == '404: Not Found'
			puts "\n#{Green}Writing #{Pink}#{(data.chars.size/1000000.0).round(2)} MB #{Green}to words. Please Wait a Moment.#{Reset}\n\n"
			file = File.open('words', 'w+')
			file.write(data)
			file.close
			puts "#{Green}All done! The file has been saved to #{Red}#{Dir.pwd}/words#{Green}. Run #{Blue}#{__FILE__}#{Green} to begin solving puzzles!#{Reset}"
			exit! 0
		else
			puts 'Uh Oh! The update is not successful. If the problem persists, please contact the developer: souravgoswami@protonmail.com'
			exit! 128
		end
	rescue Exception
		puts "The site https://raw.githubusercontent.com/Souravgoswami/jmblr/master/word is not reachable at the moment."
		puts "Please make sure that you have an active internet connection."
		exit! 127
		end
end

$status = nil

puts "#{[Red, Green, Blue, Pink].sample}#{['Please Wait a Moment', 'Just a Second!', 'Umm...', 'Hi there!'].sample}#{Reset}"
Thread.new { loop do '|/-\\'.chars do |c| print "#{c}\r" ; sleep 0.03 ; break if $status end end }

unsorted = File.open('words').readlines.map(&:chomp).map(&:downcase).select { |i| i =~ /^[a-z]+$/}.uniq
sortedwords = unsorted.map do |ch| ch.split('').sort.join end
$status = 1

unless ARGV.empty?
	puts "\033[H\033[J#{Green}Matches for #{Pink}#{ARGV.join(', ')}#{Green}:#{Reset}"
	ARGV.each do |index|
		w = index.downcase.split('').sort.join
		sortedwords.each_with_index do |sw, i| puts "#{Red}#{unsorted[i]}#{Reset}" if sw == w end
		puts "#{Green}=" * %x(tput cols).to_i
	end
else
	puts "\033[H\033[J#{['Hi! Give me jumbled words!', 'Type me some words', 'Alright... Ready?'].sample}...\r"
	rndwrd, c, w, search = sortedwords.sample, '', '', '', ''
	loop do
		c = inp = STDIN.getch
		print "\033[H\033[J"
		exit! 0 if c === "\e"
		if c == "\r" then c = ''
			elsif c == "\u007F" then search.chop! unless search.empty? ; w = search
			else w += c ; search += c end

		puts "#{Blue}=" * %x(tput cols).to_i + "#{Red}Possible Matches for #{Red}#{search}:#{Reset}" unless search.empty?
		puts "#{Blue}=" * %x(tput cols).to_i
		puts "#{Blink}#{['Type a jumble word!', 'Type a word', 'Press esc when you are done!'].sample}#{Reset}\r" if search.empty?

		w = w.downcase.split('').sort.join
		sortedwords.each_with_index do |sw, i| puts "#{Red}#{unsorted[i]}#{Reset}" if sw == w end
		rndwrd = sortedwords.sample if (!rndwrd.start_with?(search) or search.empty?) and (inp.ord != 127 or rndwrd != search)
		puts "#{Blue}=" * %x(tput cols).to_i + "#{Red}Search For: #{Pink}#{search}#{Reset}"
		puts "\n" * (%x(tput lines).to_i/3) + "\033[38;5;170mA fun challenge for you, can you solve \033[38;5;#{rand(30..40)}m#{rndwrd}#{Reset}?\r"
	end
end
