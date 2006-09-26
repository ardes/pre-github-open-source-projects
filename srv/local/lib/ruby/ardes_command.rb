# simple lib for setting up command line programs

# Example of use:
#
#   require File.dirname(__FILE__) + '/../lib/ruby/ardes_command'
#   
#   $COMMAND = File.basename(__FILE__)
#   $PATH    = File.expand_path(File.dirname(__FILE__))
#   $SRC_DIR = File.expand_path("#{$PATH}/../share/#{$COMMAND}")
#   
#   $TASKS      = [:svn, :trac, :trac_ini, :trac_perms]
#   $ARGUMENTS  = [:project, [:name, :project], [:description, :name], [:url, '']]
#   $OPTIONS    = [
#     ["--help",               "-h",   GetoptLong::NO_ARGUMENT],
#     ["--svn-dir",                    GetoptLong::REQUIRED_ARGUMENT],
#     ["--trac-dir",                   GetoptLong::REQUIRED_ARGUMENT],
#     ["--trac-db",                    GetoptLong::REQUIRED_ARGUMENT],
#     ["--trac-templates-dir",         GetoptLong::REQUIRED_ARGUMENT],
#     ["--src-dir",                    GetoptLong::REQUIRED_ARGUMENT]
#   ]
#
# Then define tasks

require 'getoptlong'

def main
  extract_options
  extract_arguments
  perform_tasks
end

def extract_options
  begin
    command_line_options.each do |name, arg|
      eval "$#{name.sub(/^--/, '').gsub('-', '_').upcase} = '#{arg}'"
    end
  rescue
    exit_with_error
  end

  exit_with_usage if $HELP
  exit_with_error if ARGV.size < 1
end

def extract_arguments
  $ARGUMENTS.each do |arg|
    default = nil
    (arg, default) = arg if arg.is_a? Array
    default = eval "$#{default.to_s.upcase}" if default.is_a? Symbol

    eval "$#{arg.to_s.upcase} = '#{ARGV.shift || default}'"
  end
end
  
def perform_tasks
  todo.each do |task|
    send task
  end
end

def file_not_there_or_force(file)
  if File.exist? file
    unless false # we're not allowing this at the moment $FORCE
      puts("#{file} exists - skipping\n")
      return false
    end
    puts "#{file} exists - deleting ...\n"
    `rm -r -i #{file}`
    puts "done, "
  end
  return true
end

def run_sh(task)
  sh = File.read "#{$SRC_DIR}/#{task}.sh"
  sh = eval "<<-end_eval
#{sh}
  end_eval"
  $DEBUG ? puts sh : `#{sh}`
end

def write_file(src, dest)
  file = File.read "#{$SRC_DIR}/#{src}"
  file = eval "<<-end_eval
#{file}
  end_eval"
  $DEBUG ? puts file : File.open(dest, 'w') { |f| f << file }
end

def command_line_options
  options = $OPTIONS
  
  $TASKS.each do |task|
    options << ["--#{task.to_s.sub('_','-')}-only", GetoptLong::NO_ARGUMENT]
    options << ["--no-#{task.to_s.sub('_','-')}", GetoptLong::NO_ARGUMENT]
  end
  
  GetoptLong.new(*options)
end

def todo
  todo = []
  $TASKS.each do |task|
    return [task] if eval "$#{task.to_s.upcase}_ONLY"
    todo.push(task) unless eval "$NO_#{task.to_s.upcase}"
  end
  todo
end

def print_usage
  puts "Usage: #{$COMMAND} [options] #{$ARGUMENTS.collect{|a| a.is_a?(Array) ? "[<#{a[0]}>]" : "<#{a}>"}.join(' ')}\n"
end

def print_help
  puts <<-end_puts
  options:
    --help                    -h
  end_puts
end

def exit_with_error(exit_code = 1)
  print_usage
  puts "For help use #{$COMMAND} --help\n"
  exit(exit_code)
end

def exit_with_usage(exit_code = 0)
  puts <<-end_puts
  #{print_usage}
  
  #{print_help}
  end_puts
  exit(exit_code)
end
