module SELinux
  # Represents a SELinux type of file, `.te` type. This class is able to parse
  # and obtain module name and version on the given file.
  class File
    attr_accessor :version, :module_name, :content

    # Class constructor. Saves the file conents on a instance variable.
    #   +content+  File.open results from a `.te` file;
    def initialize(content = nil)
      raise 'No SELinux content informed!' if content.nil? || content.empty?

      @content = content
      @version = nil
      @module_name = nil

      parse
    end

    # Reads `.te` file contents line-by-line, keeping a counter to track line
    # numbers and only the first 20% of the file will be considered, using
    # SELinux conventions.
    def parse
      # reading about twenty percente of the file lenght
      read_line_limit = ((@content.length * 2) / 10).ceil + 1

      line_number = 1
      @content.each_line do |line|
        break if line_number >= read_line_limit
        line.chomp

        # extracting version and module name
        if (match = line.match(/^module\s+([\w_-]+)\s+([\d\.\-]+);/))
          @module_name, @version = match.captures
        end

        break if @version && @module_name
        line_number += 1
      end
    end
  end
end
