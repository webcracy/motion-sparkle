# frozen_string_literal: true

# https://makandracards.com/makandra/6087-ruby-indent-a-string
String.class_eval do
  def indent(count, char = ' ', skip_first_line: false)
    gsub(/([^\n]*)(\n|$)/) do |_match|
      last_iteration = (Regexp.last_match(1) == '' && Regexp.last_match(2) == '')
      line = String.new
      line << (char * count) unless last_iteration || skip_first_line
      line << Regexp.last_match(1)
      line << Regexp.last_match(2)

      skip_first_line = false

      line
    end
  end
end
