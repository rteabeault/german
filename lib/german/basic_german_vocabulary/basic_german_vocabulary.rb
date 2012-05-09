require 'nokogiri'
require 'open-uri'
require 'fileutils'

module BasicGermanVocabularyDotInfo
  extend FileUtils

  BASE_URL = "http://www.basic-german-vocabulary.info"
  LESSONS_URL = "#{BASE_URL}/lessons/index-of-lessons.html"
  ROOT_DIR = mkdir_p("basic-german-vocabulary.info", :verbose => false)
  AUDIO_DIR = mkdir_p(File.join(ROOT_DIR, "audio"), :verbose => false)

  class WordFetcher

    def write_sentences_csv(lesson_range)
      File.open(File.join(ROOT_DIR, 'sentences.csv'), 'w') do |file|
        process_words(lesson_range) do |lesson, exercise, word|
          word.sentences.each do |sentence|
            file.puts [
              sentence.as_html, 
              word.as_html, 
              word.translation, 
              "[sound:#{word.audio}.mp3]", 
              "#{lesson.name} #{exercise.name}"
            ].join("\t")
          end
        end
      end
    end

    def write_nouns_csv(lesson_range)
      File.open(File.join(ROOT_DIR, 'nouns.csv'), 'w') do |file|
        process_words(lesson_range) do |lesson, exercise, word|
          next unless word.kind_of? Noun
          file.puts [
            word.gender,
            word.base_word_as_html,
            word.plural,
            word.translation, 
            "[sound:#{word.audio}.mp3]", 
            "#{lesson.name} #{exercise.name}"
          ].join("\t") 
        end
      end
    end

    def write_verbs_csv(lesson_range)
    end

    def download_audio(lesson_range)
      process_words(lesson_range) do |lesson, exercise, word|
        audio_file = File.join(AUDIO_DIR, "#{word.audio}.mp3")
        Dwelle::HTTP.download("#{BASE_URL}/snw/#{word.audio}.mp3", audio_file) unless File.exist? audio_file
      end
    end

    def process_words(range, &block)
      lessons(range).each do |lesson|
        lesson.exercises.each do |exercise|
          exercise.words.each do |word|
            yield lesson, exercise, word
          end
        end
      end
    end

    def lessons(range)
      @lessons ||= range.collect do |lesson_number| 
        Lesson.new("#{BASE_URL}/lessons/#{lesson_number}.html", lesson_number)
      end
    end
  end

  class Lesson
    attr_reader :name, :exercises

    def initialize(url, lesson_number)
      @url = url
      @name = "Lesson_#{lesson_number}"

      exercises = page.search("//div[@id='col_b']//dl[@class='dtbolda']//dt").collect { |exercise| exercise.text }
      words = page.search("//div[@id='col_b']//dl[@class='dtbolda']//dd")
      @exercises = exercises.zip(words).collect do |exercise| 
        Exercise.new(exercise[0], exercise[1])
      end
    end

    def page
      @page ||= lambda do
        puts "Loading lesson #{name} from #{@url}"
        Nokogiri::HTML(open(@url))
      end.call
    end
  end

  class Exercise
    attr_reader :name, :words

    def initialize(name, html)
      @name = name.gsub(" ", "_")
      @words = html.search("a").collect do |a_element|
        Word.from_page "#{BASE_URL}#{a_element['href']}" 
      end.compact
    end
  end

  class Word
    attr_reader :as_html, :as_text, :sentences, :audio, :translation

    def self.from_page(url)
      puts "Loading word from #{url}"
      begin 
        page = Nokogiri::HTML(open(url))
      rescue => e
        puts "Could not open url #{e}"
        return nil
      end

      word_box = page.at("//div[@id='col_b']")
      word_span = word_box.xpath("//dl/dt/span")[0]
      case word_span['class']
      when "vb"
        Verb.new(word_box)
      when /(der|die|das)/
        Noun.new(word_box)
      else
        Word.new(word_box)
      end
    end

    def initialize(html)
      word = html.search("//dl/dt/span[1]")
      @as_text = word.text
      @as_html = word.to_html
      @translation = html.search("//dl//dt//span[@class='tr']").children[0].text.strip
      @sentences = html.css("dl dd").collect { |sentence| Sentence.new(sentence) }

      flash_vars = html.at_css("dl dt object param[name='FlashVars']")['value']
      @audio = /mp3=\/snw\/(?<audio>.*)\.mp3/.match(flash_vars)[1]
    end
  end

  class Noun < Word
    attr_reader :gender, :plural

    def initialize(word_html)
      super(word_html)

      @gender = as_text.split(" ")[0]
      @plural = (as_text.split(",")[1] || "").strip
    end
  end

  class Verb < Word
    attr_reader :infinitive

    def initialize(html)
      super(html)
      verb_parts = html.search("//dl//dt//span[@class='tr']").children[1]
      @as_text = as_text << " " << verb_parts.text
      @as_html = as_html << " " << verb_parts.to_html
    end

    # Verb - infinitive, 3rd per. sing. pres., 3rd per. sing. past, past participle, auxiliary verb
  end

  class Sentence
    attr_reader :sentence, :as_html

    def initialize(html)
      html = sanitize(html)
      @sentence = html.text
      @as_html = html.to_html
    end

    def sanitize(sentence_html)
      children = sentence_html.children
      if children[0].text =~ /^\d*\.\s$/
        children.delete(children[0])
      else
        children[0].content = children[0].content.gsub(/^\d*\.\s/, "")
      end
      children
    end
  end
end