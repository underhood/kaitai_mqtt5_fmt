IFNDEF = '#ifndef'
IFDEF  = '#ifdef'
ENDIF = '#endif'
DEFINE = '#define'
UNDEF = '#undef'
VALID_SYMBOL_REGEX = '([a-zA-Z_][0-9a-zA-Z_\-]*)'
$strict_block = false
$line = 0

define_parser = /^\s*#{DEFINE} #{VALID_SYMBOL_REGEX}\s*((\/(\*|\/)).*)?$/
undef_parser = /^\s*#{UNDEF} #{VALID_SYMBOL_REGEX}\s*((\/(\*|\/)).*)?$/
ifdef_parser  = /^#{IFDEF} #{VALID_SYMBOL_REGEX}\s*((\/(\*|\/)).*)?$/
ifdef_parser  = /^#{IFDEF} #{VALID_SYMBOL_REGEX}\s*((\/(\*|\/)).*)?$/
ifndef_parser = /^#{IFNDEF} #{VALID_SYMBOL_REGEX}\s*((\/(\*|\/)).*)?$/
endif_parser  = /^#{ENDIF}\s*((\/(\*|\/)).*)?$/
stack = []
defined_symbols = []

next_is_symbol = false
while (arg = ARGV.shift) != nil
    if next_is_symbol
        next_is_symbol = false
        unless arg =~ /^#{VALID_SYMBOL_REGEX}$/
            STDERR.puts "Symbol name \"#{arg}\" not valid"
            exit -2
        end
        defined_symbols.push $1
        next
    end
    if arg =~ /^-D/
        if arg.length == 2
            next_is_symbol = true
            next
        end
        unless arg =~ /^-D#{VALID_SYMBOL_REGEX}$/
            STDERR.puts "Symbol name \"#{arg[(2..)]}\" not valid"
            exit -2
        end
        defined_symbols.push $1
        next
    end
    STDERR.puts "Unknown commandline argument \"#{arg}\""
    exit -1
end

while gets
    $line += 1
    $_.chomp!
    if $_ =~ /^#{IFDEF}/
        unless ifdef_parser.match($_)
            STDERR.puts "Syntax error (parsing #{IFDEF}) at line:#{$line}."
            exit 1
        end
        stack.push [$1, defined_symbols.include?($1)]
        next
    end
    if $_ =~ /^#{IFNDEF}/
        unless ifndef_parser.match($_)
            STDERR.puts "Syntax error (parsing #{IFNDEF}) at line:#{$line}."
            exit 2
        end
        stack.push [$1, !defined_symbols.include?($1)]
        next
    end
    unless stack.any? {|i| i[1] == false}
        if $_ =~ /^\s*#{DEFINE}/
            unless define_parser.match($_)
                STDERR.puts "Syntax error (parsing #{DEFINE}) at line:#{$line}"
                exit 4
            end
            defined_symbols.push $1
            next
        end
        if $_ =~ /^\s*#{UNDEF}/
            unless undef_parser.match($_)
                STDERR.puts "Syntax error (parsing #{UNDEF}) at line:#{$line}"
                exit 5
            end
            unless defined_symbols.include? $1
                STDERR.puts "Warning: #{UNDEF} at line:#{$line} undefines symbol that is not defined"
            end
            defined_symbols.delete $1
            next
        end
    end
    if $_ == "#_dump_all_symbols"
        puts "// DEBUG SYMBOL DUMP (req@line:#{$line}): #{defined_symbols.inspect}"
    end
    if endif_parser.match($_)
        if stack.pop == nil
            STDERR.puts "Unexpected #endif at line:#{$line}"
            exit 6
        end
        next
    end
    unless stack.any? {|i| i[1] == false}
        puts $_
    end
end

exit 0
