IMAGE_TYPES = [".jpg", ".jpeg"]

class FileOrganizer
  OTHER_DIR = "Other"

  def initialize source_path, dest_dir, threshold
    @source_path = source_path
    @dest_dir = dest_dir
    @threshold = threshold

    puts "Threshold: #{@threshold}"
  end

  def ext
    File.extname(@source_path.downcase)
  end

  def is_image?
    #[".jpg", ".jpeg"].include? ext
    IMAGE_TYPES.include? ext
  end

  def timestamp(file = nil)
    file = @source_path if file == nil
    begin
      exif_file = EXIFR::JPEG.new file
      if exif_file.exif? && exif_file.date_time
        return exif_file.date_time
      else
        return File.new(file).ctime
      end
    rescue
      return File.new(file).ctime
    end
  end

  def original_name
    File.basename @source_path
  end

  def original_name_without_ext
    original_name.chomp(File.extname(original_name) )
  end

  def path_with_timestamp_without_ext
    file_timestamp = timestamp
    if is_image?
      #return "#{@dest_dir}#{File::SEPARATOR}#{file_timestamp.year}#{File::SEPARATOR}#{file_timestamp.strftime("%b")}#{File::SEPARATOR}#{file_timestamp.strftime("%d - %a")}#{File::SEPARATOR}#{file_timestamp.strftime("%I:%M:%S %p")} - #{original_name_without_ext}"
      return "#{@dest_dir}#{File::SEPARATOR}#{file_timestamp.year}#{File::SEPARATOR}#{file_timestamp.strftime("%b")}#{File::SEPARATOR}#{file_timestamp.strftime("%d-%a")}#{File::SEPARATOR}#{file_timestamp.strftime("%I-%M-%S-%p")}"
    else
      return "#{@dest_dir}#{File::SEPARATOR}#{OTHER_DIR}#{File::SEPARATOR}#{original_name_without_ext}"
    end
  end

  def path_with_timestamp(append = "")
    return "#{path_with_timestamp_without_ext}#{append}#{ext}"
  end

  def file_with_same_name_exists?(path)
    exists = File.exists? path
    #puts "File #{path} exists = #{exists}"
    return exists
  end

  def dest_path(mode, append = "")

    path = path_with_timestamp(append)
    count = 1
    while(file_with_same_name_exists?(path))
      #puts "File #{path} exists, incrementing"
      path = path_with_timestamp("#{append}-COPY_#{count}")
      count += 1
    end

    return path
  end

  def is_duplicate?(fingerprints, hash)
    return fingerprints.get_matches?(hash, @threshold)
  end

  def copy(fingerprints)

    # Need to check for duplicates

    image_hash = PHash::image_hash(@source_path)
    #puts "DUP DETECTION for: #{image_hash}"
    dup_hash = is_duplicate?(fingerprints, image_hash) #dup_hash is either the hash of a duplicate image or false
    if dup_hash != false
      # Found a duplicate image.
      puts "FOUND A DUP"

      distance = dup_hash.distance(image_hash)
      puts "FOUND DISTANCE: #{distance}"
      if distance == 0
        puts "SKIPPING EXACT MATCH"
        return
      end

      puts "WILL MARK AS DUP"
      # Need to find a suitable name for the dup
      dup_timestamp = timestamp(dup_hash.path)
      append = "-DUPLICATE_OF-#{dup_timestamp.year}-#{dup_timestamp.strftime("%b")}-#{dup_timestamp.strftime("%d")}-#{dup_timestamp.strftime("%I-%M-%S-%p")}"
      puts "Appending: #{append}"
      dest_path_v = dest_path(MARK_DUPS, append)
      puts "Destination path: #{dest_path_v}"
    else
      puts "NOT A DUPE"
      dest_path_v = dest_path(NOT_A_DUP) #-1 to skip the duplicate
    end

    #irrespective of if it is a dup or not, save the fingerprint.
    # change the path in the hash to the file's new path
    image_hash.path = dest_path_v
    fingerprints.add image_hash

    puts "COPYING: #{@source_path} to #{dest_path_v}"
    puts " "
    FileUtils.mkdir_p File.dirname dest_path_v
    FileUtils.cp  @source_path, dest_path_v
  end
end