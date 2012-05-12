# encoding: utf-8

class Langenscheidt
  attr_reader :notes

  def initialize(csv)
    @notes = File.open(csv, 'r') do |file|
      file.readlines.collect { |line| Note.new(line) }
    end

    @notes.each { |note| puts note.german }
  end
end

class Note
  attr_reader :sentence, :translation, :german, :english, :gender

  def initialize(line)
    @sentence, @translation, @german, @english, gender = line.split("\t")
    sanitize_english!
    sanitize_german!
  end

  def sanitize_english!
    @english.chomp!(" n")
    @english.chomp!(" v")
  end

  def sanitize_german!

    # reißen V/t., i., + Präp. (an, um, weg, u.a.), riss, hat (ist) gerissen
    @german.gsub!(/\+\sPräp.\s\(.*?\)(,\s)?/, "")
    @german.gsub!(/hat\s\(ist\)/, "hat/ist")
    
    if @german =~ /V\/i|V\/t|i\.,|refl\.,/
      parts = @german.split(/\s(?:V\/|Mod|i|refl).*(?:\.,?)(?:\s\(.*\),\s)?/)
      @german = "#{parts[0]}"
      @german << " (#{parts[1].strip})" if parts[1]
    end

    @german.gsub!(/Pron.,?\s*/, "")

    # an Präp. (+ Dat., Akk.) => an Präp.
    # TODO ausschließlich Adv., Präp. (+ Gen. a. Dat.)
    @german.gsub!(/\s\(\+\s.*\)/, "")

    # an Präp.
    @german.chomp!("Präp.")
    @german.chomp!(" Adj.")
    @german.chomp!(" Adv.")
    @german.chomp!(" Pron.")
    @german.chomp!(" Konj.")

    # Adjectives /^(.*)\sAdj\.,?\s?(.*)/
    if @german =~ /^(.*)\sAdj\.,?\s?(.*)/
      @german = $1
      @german << " (#{$2})" if $2.length > 0
    end

    
    if @german =~ /(.*?)\s(m|f|n),(.*)/
      gender = "der" if $2 == "m"
      gender = "die" if $2 == "f"
      gender = "das" if $2 == "n"
      @german = "#{gender} #{$1}#{$3}"

      #handle feminine occupations
      if @german =~ /(.*)\b(\p{Word}+)\b\sf,\s(.*)/
        @german = "#{$1.chomp(", ")} / die #{$2} #{$3}"
      end

      if @german =~ /(der|die|das)\s(\w+)\s(.*)\s\/\s(die)\s(\w+)\s(.*)/
        @german = "#{$1} #{$2} (#{$3}) / #{$4} #{$5} (#{$6})"
      end
    end
  end
end
