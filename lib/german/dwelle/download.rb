require 'net/http'
require 'net/https'
require 'progressbar'

module Dwelle
  module HTTP
    def self.download(url, dest_file)
      pbar = nil

      content_length_proc = lambda do |content_length| 
        if content_length
          pbar = ProgressBar.new("Downloading:", content_length)
          pbar.file_transfer_mode
        else
          puts "Could not determine content-length.  Download progress will not be shown"
        end
      end

      progress_proc = lambda do |size| 
        pbar.set(size) unless pbar.nil?
      end

      puts "#{url} => #{dest_file}"
      open(url, "r", :content_length_proc => content_length_proc, :progress_proc => progress_proc) do |input|
        open(dest_file, "wb") do |output|
          while (buffer = input.read(8 * 1024))
            output.write(buffer)
          end
          pbar.finish unless pbar.nil?
        end
      end
    end
  end
end