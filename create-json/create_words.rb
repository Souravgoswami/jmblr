require 'json'
require 'zlib'

# Skip if word is less than minimum length
MINIMUM_LENGTH = 3

# Minimum match for question; minimum length for question words
MINIMUM_QUESTION_MATCHES = 4
MINIMUM_QUESTION_WORD_LENGTH = 5

words1 = {}
counts = {}

IO.readlines(File.join(__dir__, 'words')).each { |x|
	x.strip!
	x.downcase!
}.uniq.each { |x|
	next if x.length < MINIMUM_LENGTH || x[/[^a-z]/]

	sorted = x.chars.sort.join

	if words1.key?(sorted)
		words1[sorted] << x
	else
		words1.store(sorted, [x])
	end
}

words1.each { |x|
	next if x[0].length < MINIMUM_QUESTION_WORD_LENGTH
	c = x[1].count
	next if c < MINIMUM_QUESTION_MATCHES

	if counts.key?(c)
		counts[c] << x[0]
	else
		counts[c] = [x[0]]
	end
}

json = {
	anagrams: words1,
	questions: counts.values.flatten.sort_by(&:length)
}.to_json

Zlib::GzipWriter.open(
	File.join(__dir__, 'words.json.gz'),
	9
) { |gz| gz.write(json) }
