# frozen_string_literal: true

# csv2tsume.rb — CSV → Moodle XML (qtype_tsumeshogi)
# Usage: ruby csv2tsume.rb input.csv > output.xml
#
# CSV列順: name, questiontext(plain), generalfeedback(plain), correctanswer, sfen

require "csv"

def xml_escape(str)
  str.to_s.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;")
     .gsub('"', "&quot;").gsub("'", "&apos;")
end

def csv2tsume_convert(csv_path)
  rows = CSV.read(csv_path, encoding: "BOM|UTF-8")
  lines = []
  lines << '<?xml version="1.0" encoding="UTF-8"?>'
  lines << "<quiz>"
  rows.each do |name, qtext, feedback, answer, sfen|
    next if name.nil? || name.strip.empty?

    lines << '  <question type="tsumeshogi">'
    lines << "    <name>"
    lines << "      <text>#{xml_escape(name.strip)}</text>"
    lines << "    </name>"
    lines << '    <questiontext format="html">'
    lines << "      <text><![CDATA[<p>#{qtext.to_s.strip}</p>]]></text>"
    lines << "    </questiontext>"
    lines << '    <generalfeedback format="html">'
    lines << "      <text><![CDATA[<p>#{feedback.to_s.strip}</p>]]></text>"
    lines << "    </generalfeedback>"
    lines << "    <defaultgrade>1.0000000</defaultgrade>"
    lines << "    <penalty>0.0000000</penalty>"
    lines << "    <hidden>0</hidden>"
    lines << "    <idnumber></idnumber>"
    lines << "    <sfen>#{xml_escape(sfen.to_s.strip)}</sfen>"
    lines << "    <correctanswer>#{xml_escape(answer.to_s.strip)}</correctanswer>"
    lines << "  </question>"
    lines << ""
  end
  lines << "</quiz>"
  "#{lines.join("\n")}\n"
end

if __FILE__ == $PROGRAM_NAME
  abort "Usage: ruby csv2tsume.rb input.csv" if ARGV.empty?
  print csv2tsume_convert(ARGV[0])
end
