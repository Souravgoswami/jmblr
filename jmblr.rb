#!/usr/bin/env ruby
# Written by Sourav Goswami - https://github.com/Souravgoswami/
# GNU General Public License v3.0

require 'io/console'
system('clear')

if !ARGV[0].match(/^[a-z]/)
puts <<EOF
Hi my name is Jumbler! Also known as jmblr...
I am a small program where you will give me a jumpled up word(s), and I try to solve that with my tiny brain.

What job can I accomplish?
	When you run me, I will ask you to type your word. I will show my calculation in real time.
	Sorry if I take some time to solve your jumbled up word - I still have to do all my calculations.
	But I will try my best to solve the word as fast as possible. Probably some milliseconds...
	Remember to press the escape key when you want to leave!

	You can pass me some command line arguments as well!
	I will accept one or more than one word as argument. I will solve them one by one.
	I will not show any result if I don't get something meaningful from your jumbled word(s).
EOF
exit! 0
end unless ARGV[0].nil?

$status, sortedwords = nil, []
puts ['Please Wait a Second', 'Just a Second!', 'Umm...', 'Hi there!'].sample
Thread.new { loop do '|/-\\'.chars do |c| print "#{c}\r" ; sleep 0.03 ; break if $status end end }

unsorted = File.open('word').readlines.map(&:chomp).map(&:downcase).select { |i| i =~ /[a-z]/}.uniq
unsorted.each do |ch| sortedwords << ch.split('').sort.join('') end
$status = 0
unless ARGV.empty?
	puts "\033[H\033[J#{['Here\'s what I found!', 'Alright... Ready!'].sample}...\r"
	ARGV.each do |index|
		sortedwords.each_with_index do |sw, i| puts "\033[1;33m#{unsorted[i]}" if sw == index.downcase.split('').sort.join('') end
		puts "\033[1;34m=" * %x(tput cols).to_i
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

		puts "\033[1;34m=" * %x(tput cols).to_i + "Possible Matches for #{search}:" unless search.empty?
		puts "\033[5m#{['Type a jumble word!', 'Type a word', 'Press esc when you are done!'].sample}\033[0m\r" if search.empty?

		w = w.downcase.split('').sort.join('')
		sortedwords.each_with_index do |sw, i| puts "\033[1;32m#{unsorted[i]}" if sw == w end

		rndwrd = sortedwords.sample if (!rndwrd.start_with?(search) or search.empty?) and (inp.ord != 127 or rndwrd != search)
		puts "\033[1;34m=" * %x(tput cols).to_i + "\033[1;34mSearch For: #{search}"
		puts "\n" * (%x(tput lines).to_i/2) + "\033[38;5;170mA fun challenge for you, can you solve \033[38;5;#{rand(30..40)}m#{rndwrd}\033[0m?\r"
	end
end
