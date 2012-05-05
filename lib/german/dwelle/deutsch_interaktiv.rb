require 'nokogiri'
require 'open-uri'

class DeutschInteraktiv
  BASE_URL = "http://www.basic-german-vocabulary.info/"
  LESSONS_URL = "#{BASE_URL}/lessons/index-of-lessons.html"

  attr_reader :lessons

  def initialize
    @lessons = (1..45).to_a.collect { |i| Lesson.new("#{BASE_URL}/lessons/#{i}.html", i) }
  end

  def fetch_words
    lessons.each do |lesson|
      lesson.words.each do |word|
        puts word.word
      end
    end
  end
end

class Lesson
  BASE_URL = "http://www.basic-german-vocabulary.info/"

  attr_reader :name

  def initialize(url, lesson_number)
    @url = url
    @name = "Lesson #{lesson_number}"
  end

  def lesson_page
    @lesson_page ||= Nokogiri::HTML(open(@url))
  end

  def words
    @words ||= lesson_page.search(".dtbolda dd a").collect {|a_element| Word.new("#{BASE_URL}#{a_element['href']}") }
  end
end

class Word
  def initialize(url)
    puts url
    @url = url
  end

  def word
    word_page.css("dl dt span")[0].text
  end

  def word_page
    @word_page ||= Nokogiri::HTML(open(@url))
  end
end
