# encoding: utf-8

class Langenscheidt
  attr_reader :notes

  def initialize(csv)
    @notes = File.open(csv, 'r') do |file|
      file.readlines.collect { |line| Note.new(line) }
    end

    output = File.join(File.dirname(csv), File.basename(csv) + ".clean.csv")
    File.open(output, 'w') do |file|
      @notes.each do |note| 
        file.puts [note.sentence, note.translation, note.german, note.english].join("\t")
      end
    end
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

    @german.chomp!("Präp.")
    @german.sub!(/\+?\sPräp\.\s\(.*?\)(\,\s)?/, "")
    @german.chomp!(" Adj.")
    @german.chomp!(" Adv.")
    @german.chomp!(" Pron.")
    @german.chomp!(" Konj.")

    @german.match(/^(.*?)\s(?=(?:refl|V\/\s?(?:t|i|I|refl)|i|Mod\.\sV)).*\.,?(.*)/) do |match|
      @german = $1
      verb_parts = $2.strip
      if verb_parts.size > 0
        @german.concat " (#{$2.strip})"
      end
    end

    @german.match(/^(.*?)\s(?=Adj|Pron|Adv).*\.,?(.*)/) do |match|
      @german = $1
      if $2 and $2.size > 0
        @german.concat " (#{$2.strip})"
      end
    end

    # Pilot m, -en, -en, Pilotin f, -, -nen
    @german.match(/(.*)\s(?=m,)m,\s(.*),\s(\b\p{word}+\b)\s(?=f,)f,\s(.*)/) do |match|
      @german = "der #{$1} (#{$2}) / die #{$3} (#{$4})"
    end

    # Zahnschmerzen nur Pl. (Zahnweh, n, -s, kein Pl.)
    @german.match(/^(\p{word}+)\snur\sPl\.\s\((\p{word}+),\s(m|f|n),\s(.*)\)/) do |match|
      @gender = gender_from_letter($3)
      @german = "#{gender} #{$2} (#{$4}) [die #{$1} nur Pl.]"
    end

    # Tote m/f, -n, -n
    @german.match(/^(\p{word}+)\sm\/f,\s(.*)/) do |match|
      @german = "der/die #{$1} (#{$2})"
    end

    # Meter m, (auch n), -s, -
    @german.match(/^(\p{word}+)\s(m|f|n),\s\(auch\s(m|f|n)\),(.*)/) do |match|
      @german = "#{gender_from_letter($2)} (auch #{gender_from_letter($3)}) #{$1} (#{$4})"
    end

    # Lokomotive f, -, -n
    @german.match(/^(\p{word}+)\s(m|f|n),\s(.*)/) do |match|
      @german = "#{gender_from_letter($2)} #{$1} (#{$3})"
    end
  end

  def gender_from_letter(gender_letter)
    case gender_letter
    when 'm' then "der"
    when 'f' then "die"
    when 'n' then "das"
    end
  end
end
