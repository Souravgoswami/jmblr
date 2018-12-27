# jmblr (jumbler - organize a shuffled word)
Type any kind of jumble word and get a meaningful word if it exists in the given word list.
It will work with most of the Linux terminals. Don't run somewhere without a TTY!

Solve any kind of jumble word with jumbler. It's short and simple.

Running the script:
  1. Make sure you have the ruby interpreter and ncurses(tput command needed).
  2. Download and extract the zip file.
  3. You can run it with ruby:
          ruby jmblr.rb
      Or you can run it with the shell:
          chmod 777 jmblr.rb
          ./jmblr.rb
    You can pass command line arguments, and can solve multiple words with a go!
        ruby jmblr triangle ceissp deiorrw
    Any invalid jumble word will not be ignored.
  5. For more help, run ./jmblr.rb -h
