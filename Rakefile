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

desc "Create tab separated file of vocabulary from basic-german-vocabulary.info"
task :deutsch_interaktiv do
  lesson_range = 1..45
  fetcher = BasicGermanVocabularyDotInfo::WordFetcher.new
  fetcher.write_sentences_csv(lesson_range)
  fetcher.write_nouns_csv(lesson_range)
  fetcher.write_verbs_csv(lesson_range)
  fetcher.download_audio(lesson_range)
end

desc "Reformat old Langenscheidt's Basic German Vocabulary to new Anki format"
task :bgv do
  csv = File.join("Langenscheidt", "Langenscheidt.csv")
  bgv = Langenscheidt.new(csv)
end