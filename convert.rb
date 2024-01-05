#!/usr/bin/env ruby
# frozen_string_literal: true

# https://en.wikipedia.org/wiki/MOI_(file_format)

def parse_moi(filename)
  data = File.read(filename)
  version = data[0..1]
  size = data[2..5].unpack1('L>')
  year = data[6..7].unpack1('S>')
  month = data[8].unpack1('C')
  day = data[9].unpack1('C')
  hour = data[0xa].unpack1('C')
  minutes = data[0xb].unpack1('C')
  milliseconds = data[0xc..0xd].unpack1('S>')
  seconds = milliseconds / 1000

  {
    version: version,
    size: size,
    year: year.to_s,
    month: month.to_s.rjust(2, '0'),
    day: day.to_s.rjust(2, '0'),
    hour: hour.to_s.rjust(2, '0'),
    minutes: minutes.to_s.rjust(2, '0'),
    seconds: seconds.to_s.rjust(2, '0')
  }
end

if ARGV.empty? || ['-h', '--help'].include?(ARGV[0])
  puts 'usage: convert.rb <directory>...'
  puts '  Convert one or more directories full of MOI and MOD files into MP4 files with correct metadata'
  return
end

ARGV.each do |dir|
  moi_files = Dir[File.join(dir, '*.MOI')]

  moi_files.each do |moi|
    data = parse_moi(moi)
    puts "#{moi}: #{data}"
    mod = moi.sub(/MOI$/, 'MOD')
    raise "Video file doesn't exist: #{mod}" unless File.exist?(mod)

    mp4 = moi.sub(/MOI$/, 'mp4')
    if File.exist?(mp4)
      puts "#{mp4} already exists, skipping"
      next
    end

    ffmpeg = "ffmpeg -i \"#{mod}\" -vcodec copy -acodec aac -metadata \"creation_time=#{data[:year]}-#{data[:month]}-#{data[:day]} #{data[:hour]}:#{data[:minutes]}:#{data[:seconds]}Z\" \"#{mp4}\""
    touch = "TZ=UTC touch -t #{data[:year]}#{data[:month]}#{data[:day]}#{data[:hour]}#{data[:minutes]}.#{data[:seconds]} \"#{mp4}\""

    system(ffmpeg)
    system(touch)
  end
end
