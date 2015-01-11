class FingerPrints

  def initialize
    @bktree = BK::Tree.new
  end

  def is_image?(file)
    [".jpg", ".jpeg"].include? File.extname(file.downcase)
  end

  def scan(path)
    if is_image?(path)
      puts "FINGERPRINTING: #{path}"
      image_hash = PHash::image_hash(path)
      @bktree.add image_hash
    else
      puts "FINGERPRINTING: SKIPPING #{path}"
    end
  end

  def get_matches?(hash, threshold)
    puts "Threshold: #{threshold}"
    #Convert threshold to a distance.
    distance = (1 - threshold) * 64
    #distance = (@threshold) * 64

    matched_prints = @bktree.query(hash, distance.ceil)

    puts "FingerPrints: distance: #{distance.ceil} : #{matched_prints}"

    if matched_prints.size > 0
      min_distance = 100 #max distance is 64, so setting to 100 guarantees that we find the best match.
      best_match = nil
      matched_prints.each { |seen, distance|
        puts "MATCHED: #{seen} distance: #{distance}"

        return seen if distance == 0 # Can't do better than an exact match.

        if (distance < min_distance)
          min_distance = distance
          best_match = seen
        end
      }

      puts "BEST MATCHED: #{best_match} distance: #{min_distance}"
      return best_match
    end
    return false
  end

  def add(hash)
    puts "Fingerprint:add -> #{hash}"
    @bktree.add hash
  end

  def dump
    pp @bktree.dump
  end

  def load(path)
    fingerprints_file = "#{path}#{File::SEPARATOR}fingerprints.data"
    if File.exists? fingerprints_file
      #@fingerprints.import(fingerprints_file)
      file = File.open(fingerprints_file, 'r')
      @bktree = Marshal.load file.read
      file.close

      return true
    else
      return false
    end

  end

  def store(path)
    fingerprints_file = "#{path}#{File::SEPARATOR}fingerprints.data"

    marshal_dump = Marshal.dump(@bktree)
    file = File.new(fingerprints_file,'w')
    file.write marshal_dump
    file.close
  end

end