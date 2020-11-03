require 'optparse'

def mv(source, target)
  command = "mv #{source} #{target}"
  puts command
  system(command)
end

class Array
  def split_at(at)
    self.partition.with_index do |_, idx| idx < at end
  end
end

def create_log_directory(directory)
  if !Dir.exists? directory
    Dir.mkdir(directory)
  end
end

def rotate_log(log_file, log_directory)
  destination = "#{log_directory}/log.0"
  mv log_file, destination
  open(destination, "a") do |f|
    f.puts "End of log - #{Time.now}\n"
  end
end

def expire_logs(max, log_file, log_directory)
  keep, delete = Dir.entries(log_directory)
    .filter do |f| f.start_with? "log." end
    .map do |f| f.slice(4, f.size).to_i end
    .sort
    .split_at(max)
  delete.each do |log|
    File.delete "#{log_directory}/log.#{log}"
  end
  keep.sort.reverse.each do |log|
    mv "#{log_directory}/log.#{log}", "#{log_directory}/log.#{log + 1}"
  end
end

Options = Struct.new(:max, :log, :old_log)

args = Options.new("log-rotate")
OptionParser.new do |opts|
  opts.banner = "Usage: log.rb [options]"
  
  opts.on("-mMAX", "--max=MAX", "Max amount of files to keep") do |v|
    args.max = v.to_i
  end
  
  opts.on("-pPATH", "--log-path=PATH", "Full path to the log file") do |v|
    args.log = v
  end
  
  opts.on("-oOLD_LOG_PATH", "--old-log-path=OLD_LOG_PATH", "Full path in which to place old logs") do |v|
    args.old_log = v
  end
end.parse!

log_directory = args.old_log
max = args.max
log_file = args.log

puts args
create_log_directory(log_directory)
rotate_log(log_file, log_directory)
expire_logs(max, log_file, log_directory)

