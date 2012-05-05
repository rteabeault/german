$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)

require 'german'

desc 'Download Top-Thema articles from dwelle.de'
task :top_thema do
  root_folder = mkdir_p File.expand_path("Top-Thema mit Vokabeln"), :verbose => false
  top_thema = TopThemaPage.new
  top_thema.download(root_folder)
end

desc 'Download Video-Thema articles from dwelle.de'
task :video_thema do
  root_folder = mkdir_p File.expand_path("Video-Thema"), :verbose => false
  video_thema = VideoThemaPage.new
  video_thema.download(root_folder)
end

task :deutsch_interaktiv do
  deutsch_interaktiv = DeutschInteraktiv.new
  deutsch_interaktiv.fetch_words
end