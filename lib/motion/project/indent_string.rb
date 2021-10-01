# https://makandracards.com/makandra/6087-ruby-indent-a-string
String.class_eval do
  def indent(count, char = ' ', skip_first_line: false)
    gsub(/([^\n]*)(\n|$)/) do |match|
      last_iteration = ($1 == "" && $2 == "")
      line = ""
      line << (char * count) unless last_iteration || skip_first_line
      line << $1
      line << $2

      skip_first_line = false

      line
    end
  end
end
