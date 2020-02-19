#!/usr/bin/ruby -w
require 'objspace'

a = IO.readlines(File.join(__dir__, 'words')).concat(IO.readlines(File.join(%w(/ usr share dict words))))
a.each { |x| x.tap(&:strip!).tap(&:downcase) }.reject! { |x| x[/[^a-z]/] }.uniq!

IO.write('words', a.join(?\n) << ?\n)
