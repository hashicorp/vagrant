module Vagrant
  module Util
    module ANSIEscapeCodeRemover
      # Removes ANSI escape code sequences from the text and returns
      # it.
      #
      # This removes all the ANSI escape codes listed here along with
      # the escape codes for VT100 terminals:
      #
      # http://ascii-table.com/ansi-escape-sequences.php
      def remove_ansi_escape_codes(text)
        # An array of regular expressions which match various kinds
        # of escape sequences. I can't think of a better single regular
        # expression or any faster way to do this.
        matchers = [/\e\[\d*[ABCD]/,       # Matches things like \e[4D
                    /\e\[(\d*;)?\d*[HF]/,  # Matches \e[1;2H or \e[H
                    /\e\[(s|u|2J|K)/,      # Matches \e[s, \e[2J, etc.
                    /\e\[=\d*[hl]/,        # Matches \e[=24h
                    /\e\[\?[1-9][hl]/,     # Matches \e[?2h
                    /\e\[20[hl]/,          # Matches \e[20l]
                    /\e[DME78H]/,          # Matches \eD, \eH, etc.
                    /\e\[[0-2]?[JK]/,      # Matches \e[0J, \e[K, etc.
                    ]

        # Take each matcher and replace it with emptiness.
        matchers.each do |matcher|
          text.gsub!(matcher, "")
        end

        text
      end
    end
  end
end
