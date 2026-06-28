# frozen_string_literal: true

# tsume2csv.rb — Moodle XML (qtype_tsumeshogi) → CSV
# Usage: ruby tsume2csv.rb input.xml > output.csv
#
# CSV列順: name, questiontext(plain), generalfeedback(plain), correctanswer, sfen

require "rexml/document"
require "csv"

def tsume2csv_convert(xml_path)
  xml = REXML::Document.new(File.read(xml_path, encoding: "UTF-8"))
  rows = []
  xml.elements.each("quiz/question") do |q|
    next unless q.attributes["type"] == "tsumeshogi"

    name      = q.elements["name/text"]&.text.to_s.strip
    qtext     = q.elements["questiontext/text"]&.text.to_s.gsub(/<[^>]+>/, "").strip
    feedback  = q.elements["generalfeedback/text"]&.text.to_s.gsub(/<[^>]+>/, "").strip
    answer    = q.elements["correctanswer"]&.text.to_s.strip
    sfen      = q.elements["sfen"]&.text.to_s.strip
    rows << [name, qtext, feedback, answer, sfen]
  end
  CSV.generate(row_sep: "\r\n") { |csv| rows.each { |r| csv << r } }
end

if __FILE__ == $PROGRAM_NAME
  abort "Usage: ruby tsume2csv.rb input.xml" if ARGV.empty?
  print tsume2csv_convert(ARGV[0])
end
