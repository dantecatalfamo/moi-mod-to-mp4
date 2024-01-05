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

  # We don't need the rest, ignore it
  #
  # duration_ms = data[0xe..0x11].unpack1('L>')
  # duration_s = duration_ms / 1000
  # aspect_ratio = data[0x80..0x83][0] # Don't care
  # audio_codec_bits = data[0x84..0x85]
  # audio_codec = if audio_codec_bits == "\x00\xC1"
  #                 'AC3'
  #               elsif audio_codec_bits == "\x40\x01"
  #                 'MPEG'
  #               else
  #                 "Unknown #{audio_codec_bits.unpack('C*').map { |x| x.to_s(16) }.join(' ')}"
  #               end
  # puts "Audio Codec: #{audio_codec}"
  # The method for calculating this on wikipedia seems to be wrong
  # audio_bitrate_bits = data[0x86].unpack1('C')
  # audio_bitrate = 64 + (audio_bitrate_bits - 1) * 16
  # puts "Audio Bitrate: #{audio_bitrate}kbit/s (#{audio_bitrate_bits.to_s(16)})"

  {
    version: version,
    size: size,
    year: year.to_s,
    month: month.to_s.rjust(2, '0'),
    day: day.to_s.rjust(2, '0'),
    hour: hour.to_s.rjust(2, '0'),
    minutes: minutes.to_s.rjust(2, '0'),
    seconds: seconds.to_s.rjust(2, '0')

    # Not needed
    #
    # milliseconds: milliseconds,
    # duration_ms: duration_ms,
    # duration_s: duration_s,
    # audio_codec: audio_codec
  }
end

if ARGV[0].nil?
  puts 'usage: convert.rb <directory>...'
  puts '  Convert a directory full of MOI and MOD files into MP4 files with correct metadata'
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
