#!/usr/bin/env ruby

require 'find'
require 'exifr'
require "fileutils"
require 'optparse'
require 'pp'
require './lib/PHash'
require './lib/BKTree'
require './lib/DirWalker'
require './file_organizer'
require './finger_prints'

class PhotoOrganizer

   def initialize
      @fingerprints = FingerPrints.new
   end

   def organize

      input_dir = '/Users/tim/Dropbox/small_pics/'
      output_dir = '/Users/tim/Downloads/small_pics/'
      threshold = '0.9'

      # If the output directory contains a fingerprints.data file, load it and skip scanning
      # else scan and load the fingerprints of all files in the output directory
      if !@fingerprints.load(output_dir)
         puts "No fingerprints.data file found. Scanning images in #{output_dir}"

         RecursiveDirWalker.new(output_dir).walk do |file|
            @fingerprints.scan(file)
         end

         # Save the scanned files so we can skip this next time.
         @fingerprints.store(output_dir)
      end
      @fingerprints.dump

      #process the new files
      RecursiveDirWalker.new(input_dir).walk do |file|
         FileOrganizer.new(file, output_dir, threshold).copy(@fingerprints)
      end

      #save the latest fingerprints so we can skip this next time.
      @fingerprints.store(options[:output_dir])
   end

end

organizer = PhotoOrganizer.new
organizer.organize