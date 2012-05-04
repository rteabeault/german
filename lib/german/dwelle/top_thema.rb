require 'nokogiri'
require 'open-uri'
require 'fileutils'

class Page
  def initialize(url)
    @url = url
  end

  def page
    @page ||= Nokogiri::HTML(open(@url))
  end
end

module HasArchivePages
  def archive_pages
    @archive_pages ||= page.search("a//[text()*='Archiv']").collect do |link|
      year = link.text.match(/.*(?<year>\d\d\d\d)/)[:year]
      create_archive_page("http://www.dw.de#{link.parent['href']}", year)
    end
  end 

  def download(to_path)
    archive_pages.each do |archive_page|
      archive_page.download(to_path)
    end
  end 
end

module HasArticlePages
  def articles
    @articles ||= page.css('div.linkList a[href*="article"]').collect do |article_link|
      title = article_link.first_element_child.text.strip
      create_article_page("http://www.dw.de#{article_link['href']}", title)
    end
  end

  def download(to_path)
    archive_path = File.join(to_path, @year)
    articles.each do |article| 
      article.download(archive_path)
    end
  end
end

class VideoThemaPage < Page
  include HasArchivePages

  def initialize
    super "http://www.dw.de/dw/0,,12165,00.html"
  end

  def create_archive_page(url, year)
    VideoThemaArchivePage.new(url, year)
  end
end

class TopThemaPage < Page
  include HasArchivePages
  def initialize
    super "http://www.dw.de/dw/0,,8031,00.html"
  end

  def create_archive_page(url, year)
    TopThemaArchivePage.new(url, year)
  end
end

class TopThemaArchivePage < Page
  include HasArticlePages

  def initialize(url, year)
    super url
    @year = year
  end

  def create_article_page(url, title)
    TopThemaArticle.new(url, title)
  end
end

class VideoThemaArchivePage < Page
  include HasArticlePages

  def initialize(url, year)
    super url
    @year = year
  end

  def create_article_page(url, title)
    VideoThemaArticle.new(url, title)
  end
end

class TopThemaArticle < Page
  
  def initialize(url, title)
    @url = url
    @title = title
  end

  def download(to_path)
    article_path = File.join(to_path, @title)
    FileUtils.mkdir_p article_path, :verbose => false

    mp3_file_path = File.join(article_path, mp3_file_name)
    Dwelle::HTTP.download(mp3_url, mp3_file_path) unless File.exist? mp3_file_path

    pdf_file_path = File.join(article_path, pdf_manuscript_file_name)
    Dwelle::HTTP.download(pdf_url, pdf_file_path) unless File.exist? pdf_file_path

    text_manuscript_file_path = File.join(article_path, text_manuscript_file_name)
    save_article_text(manuscript_text, text_manuscript_file_path) unless File.exist? text_manuscript_file_path
  end
  
  private 

  def save_article_text(text, dest_file)
    File.open(dest_file, 'wb') { |f| f << text }
  end

  def page
    @page ||= Nokogiri::HTML(open(@url))
  end

  def pdf_url
    @pdf_url ||= "http://www.dw.de#{pdf_uri}"
  end

  def mp3_url
    @mp3_url ||= mp3_popup_page.at_css("a[href$='.mp3']")['href']
  end

  def manuscript_text
    @manuscript_text ||= page.css("div[class='longText']").text.squeeze(" ").squeeze("\n")
  end

  def pdf_uri
    @pdf_uri ||= page.at_css("a[href$='.pdf']")['href']
  end

  def mp3_popup_link
    @mp3_popup_link ||= page.at_xpath("//a/h2[contains(text(), 'als MP3')]/..")
  end

  def mp3_popup_page
    @mp3_popup_page ||= Nokogiri::HTML(open("http://www.dw.de#{mp3_popup_link['href']}"))
  end

  def mp3_file_name
    "#{@title}.mp3"
  end

  def pdf_manuscript_file_name
    "#{@title}.pdf"
  end

  def text_manuscript_file_name
    "#{@title}.txt"
  end
end

class VideoThemaArticle < Page
  
  def initialize(url, title)
    @url = url
    @title = title
  end

  def download(to_path)
    article_path = File.join(to_path, @title)
    FileUtils.mkdir_p article_path, :verbose => false

    # mp4_file_path = File.join(article_path, mp4_file_name)
    # Dwelle::HTTP.download(mp4_url, mp4_file_path) unless File.exist? mp4_file_path

    pdf_manuscript_file_path = File.join(article_path, pdf_manuscript_file_name)
    Dwelle::HTTP.download(pdf_manuscript_url, pdf_manuscript_file_path) unless File.exist? pdf_manuscript_file_path

    pdf_aufgaben_file_path = File.join(article_path, pdf_aufgaben_file_name)
    Dwelle::HTTP.download(pdf_aufgaben_url, pdf_aufgaben_file_path) unless File.exist? pdf_aufgaben_file_path
  end
  
  private 

  def pdf_manuscript_url
    @pdf_manuscript_url ||= "http://www.dw.de#{pdf_manuscript_uri}"
  end

  def pdf_manuscript_uri
    @pdf_manuscript_uri ||= page.at_xpath("//a/h2[contains(text(), 'Manuskript und Glossar zum Ausdrucken (PDF)')]/..")['href']
  end

  def pdf_aufgaben_url
    @pdf_aufgaben_url ||= "http://www.dw.de#{pdf_aufgaben_uri}"
  end

  def pdf_aufgaben_uri
    @pdf_aufgaben_uri ||= page.at_xpath("//a/h2[contains(text(), 'Die Aufgaben zum Ausdrucken (PDF)')]/..")['href']
  end

  def mp4_url
    @mp4_url ||= mp4_popup_page.at_css("a[href$='.mp4']")['href']
  end

  def mp4_popup_link
    @mp4_popup_link ||= page.at_xpath("//a/h2[contains(text(), 'als MP4')]/..")
  end

  def mp4_popup_page
    @mp4_popup_page ||= Nokogiri::HTML(open("http://www.dw.de#{mp4_popup_link['href']}"))
  end

  def mp4_file_name
    "#{@title}.mp4"
  end

  def pdf_manuscript_file_name
    "#{@title}-Manuskript.pdf"
  end

  def pdf_aufgaben_file_name
    "#{@title}-Aufgaben.pdf"
  end
end