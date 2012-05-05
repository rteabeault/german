require 'nokogiri'
require 'open-uri'
require 'fileutils'

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

module HasFiles
  def download_file(url_method, file_path)
    unless File.exist? file_path
      url = send(url_method)
      if url
        Dwelle::HTTP.download(url, file_path)
      else
        puts "MISSING url for #{file_path}"
      end    
    end
  end
end

class Page
  def initialize(url)
    @url = url
  end

  def page
    @page ||= Nokogiri::HTML(open(@url))
  end

  def find_href(query)
    href = page.at(query)
    if href
      href['href']
    else
      nil
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
  include HasFiles
  
  def initialize(url, title)
    @url = url
    @title = title
  end

  def download(to_path)
    article_path = File.join(to_path, @title)
    FileUtils.mkdir_p article_path, :verbose => false

    download_file(:mp3_url, File.join(article_path, mp3_file_name))
    download_file(:pdf_url, File.join(article_path, pdf_manuscript_file_name))

    text_manuscript_file_path = File.join(article_path, text_manuscript_file_name)
    save_article_text(manuscript_text, text_manuscript_file_path) unless File.exist? text_manuscript_file_path
  end

  def page
    @page ||= lambda {
      page = Nokogiri::HTML(open(@url))
      alternative_link = page.at_xpath("//a/h2[contains(text(), 'Deutsch lernen mit DW-WORLD')]/..")
      page = Nokogiri::HTML(open(alternative_link['href'])) if alternative_link
      page
    }.call
  end

  def save_article_text(text, dest_file)
    File.open(dest_file, 'wb') { |f| f << text }
  end

  def pdf_url
    uri = find_href("a[href$='.pdf']")
    return nill unless uri
    "http://www.dw.de#{uri}"
  end

  def mp3_url
    mp3_popup_page.find_href("a[href$='.mp3']")
  end

  def manuscript_text
    @manuscript_text ||= page.css("div[class='longText']").text.squeeze(" ").squeeze("\n")
  end

  def mp3_popup_link
    find_href("//a/h2[contains(text(), 'MP3')]/..")
  end

  def mp3_popup_page
    return nil unless mp3_popup_link
    @mp3_popup_page ||= Page.new("http://www.dw.de#{mp3_popup_link}")
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
  include HasFiles
  
  def initialize(url, title)
    @url = url
    @title = title
  end

  def download(to_path)
    puts "Checking #{@title}"
    article_path = File.join(to_path, @title)
    FileUtils.mkdir_p article_path, :verbose => false

    download_file(:mp4_url, File.join(article_path, mp4_file_name))
    download_file(:pdf_manuscript_url, File.join(article_path, pdf_manuscript_file_name))
    download_file(:pdf_aufgaben_url, File.join(article_path, pdf_aufgaben_file_name))
  end
  
  def pdf_manuscript_url
    uri = find_href("//a/h2[contains(text(), 'Manuskript und Glossar zum Ausdrucken (PDF)')]/..")
    return nil unless uri
    "http://www.dw.de#{uri}"
  end

  def pdf_aufgaben_url
    uri = find_href("//a/h2[contains(text(), 'Die Aufgaben zum Ausdrucken (PDF)')]/..")
    return nil unless uri
    "http://www.dw.de#{uri}"
  end

  def mp4_url
    return nil unless mp4_popup_page
    mp4_popup_page.find_href("a[href$='.mp4']")
  end

  def mp4_popup_link
    find_href("//a/h2[contains(text(), 'MP4')]/..")
  end

  def mp4_popup_page
    return nil unless mp4_popup_link
    @mp4_popup_page ||= Page.new("http://www.dw.de#{mp4_popup_link}")
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