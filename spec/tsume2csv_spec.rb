# frozen_string_literal: true

# spec/tsume2csv_spec.rb
#
# 前提: spec/ ディレクトリに tsume.csv と tsume.xml を置いた状態で実行する。
# 実行: bundle exec rspec spec/tsume2csv_spec.rb
#       または rspec spec/tsume2csv_spec.rb

require "rspec"
require "csv"
require "rexml/document"
require "tempfile"

SPEC_DIR  = __dir__
ROOT_DIR  = File.expand_path("..", SPEC_DIR)
CSV_PATH  = File.join(SPEC_DIR, "tsume.csv")
XML_PATH  = File.join(SPEC_DIR, "tsume.xml")

# テスト対象の関数を読み込む（__FILE__ == $0 ガードがあるので副作用なし）
load File.join(ROOT_DIR, "lib/tsume2csv/tsume2csv.rb")
load File.join(ROOT_DIR, "lib/tsume2csv/csv2tsume.rb")

# ── フィクスチャの期待値 ──────────────────────────────────────────────────────
EXPECTED_ROWS = [
  {
    name: "003",
    qtext: "問題3",
    feedback: "正解: 5二金",
    answer: "G*5b",
    sfen: "4k4/9/4P4/9/9/9/9/9/9 b G17p4l4n4s3g2b2r 1"
  },
  {
    name: "004",
    qtext: "問題4",
    feedback: "正解: 2三桂不成",
    answer: "3e2c",
    sfen: "6snk/7bl/8p/9/6N2/9/9/9/9 b 17p3l2n3s4gb2r 1"
  }
].freeze

# ── tsume2csv_convert ─────────────────────────────────────────────────────────
RSpec.describe "tsume2csv_convert" do
  subject(:csv_output) { tsume2csv_convert(XML_PATH) }

  let(:rows) { CSV.parse(csv_output) }

  it "フィクスチャ XML が存在する" do
    expect(File).to exist(XML_PATH)
  end

  it "問題数が正しい" do
    expect(rows.size).to eq EXPECTED_ROWS.size
  end

  it "行末が CR+LF である" do
    lines = csv_output.split("\n")
    lines.each do |line|
      expect(line).to end_with("\r"), "行末がCR+LFでない: #{line.inspect}"
    end
  end

  it "各行が5列である" do
    rows.each { |row| expect(row.size).to eq 5 }
  end

  EXPECTED_ROWS.each_with_index do |expected, i|
    context "#{i + 1}問目 (#{expected[:name]})" do
      subject(:row) { rows[i] }

      it "name が正しい" do
        expect(row[0]).to eq expected[:name]
      end

      it "qtext が正しい" do
        expect(row[1]).to eq expected[:qtext]
      end

      it "feedback が正しい" do
        expect(row[2]).to eq expected[:feedback]
      end

      it "answer が正しい" do
        expect(row[3]).to eq expected[:answer]
      end

      it "sfen が正しい" do
        expect(row[4]).to eq expected[:sfen]
      end
    end
  end

  it "HTMLタグを含まない" do
    rows.flatten.compact.each do |cell|
      expect(cell).not_to match(/<[^>]+>/)
    end
  end

  it "<!-- question: ... --> コメントを含まない" do
    expect(csv_output).not_to match(/<!--.*?question.*?-->/)
  end
end

# ── csv2tsume_convert ─────────────────────────────────────────────────────────
RSpec.describe "csv2tsume_convert" do
  subject(:xml_output) { csv2tsume_convert(CSV_PATH) }

  let(:doc)       { REXML::Document.new(xml_output) }
  let(:questions) { [].tap { |qs| doc.elements.each("quiz/question") { |q| qs << q } } }

  it "フィクスチャ CSV が存在する" do
    expect(File).to exist(CSV_PATH)
  end

  it "XML宣言で始まる" do
    expect(xml_output).to start_with('<?xml version="1.0" encoding="UTF-8"?>')
  end

  it "有効なXMLである" do
    expect { REXML::Document.new(xml_output) }.not_to raise_error
  end

  it "ルート要素が <quiz> である" do
    expect(doc.root.name).to eq "quiz"
  end

  it "問題数が正しい" do
    expect(questions.size).to eq EXPECTED_ROWS.size
  end

  it '全問題の type 属性が "tsumeshogi" である' do
    questions.each do |q|
      expect(q.attributes["type"]).to eq "tsumeshogi"
    end
  end

  it "<!-- question: ... --> コメントを含まない" do
    expect(xml_output).not_to match(/<!--.*?question.*?-->/)
  end

  EXPECTED_ROWS.each_with_index do |expected, i|
    context "#{i + 1}問目 (#{expected[:name]})" do
      subject(:q) { questions[i] }

      it "name が正しい" do
        expect(q.elements["name/text"].text.strip).to eq expected[:name]
      end

      it "questiontext に問題文が含まれる" do
        expect(q.elements["questiontext/text"].text).to include(expected[:qtext])
      end

      it "questiontext が CDATA + <p> 形式である" do
        expect(xml_output).to include("<![CDATA[<p>#{expected[:qtext]}</p>]]>")
      end

      it "generalfeedback が正しい" do
        expect(q.elements["generalfeedback/text"].text).to include(expected[:feedback])
      end

      it "generalfeedback が CDATA + <p> 形式である" do
        expect(xml_output).to include("<![CDATA[<p>#{expected[:feedback]}</p>]]>")
      end

      it "sfen が正しい" do
        expect(q.elements["sfen"].text.strip).to eq expected[:sfen]
      end

      it "correctanswer が正しい" do
        expect(q.elements["correctanswer"].text.strip).to eq expected[:answer]
      end

      it "defaultgrade が 1.0000000 である" do
        expect(q.elements["defaultgrade"].text.strip).to eq "1.0000000"
      end

      it "penalty が 0.0000000 である" do
        expect(q.elements["penalty"].text.strip).to eq "0.0000000"
      end

      it "hidden が 0 である" do
        expect(q.elements["hidden"].text.strip).to eq "0"
      end
    end
  end
end

# ── 往復変換 (round-trip) ─────────────────────────────────────────────────────
RSpec.describe "往復変換 (round-trip)" do
  context "XML → CSV → XML: sfen と correctanswer が保持される" do
    let(:original)  { REXML::Document.new(File.read(XML_PATH, encoding: "UTF-8")) }
    let(:roundtrip) { REXML::Document.new(csv2tsume_convert(CSV_PATH)) }

    it "sfen が一致する" do
      orig = [].tap { |a| original.elements.each("quiz/question/sfen")  { |e| a << e.text.strip } }
      rt   = [].tap { |a| roundtrip.elements.each("quiz/question/sfen") { |e| a << e.text.strip } }
      expect(rt).to eq orig
    end

    it "correctanswer が一致する" do
      orig = [].tap { |a| original.elements.each("quiz/question/correctanswer")  { |e| a << e.text.strip } }
      rt   = [].tap { |a| roundtrip.elements.each("quiz/question/correctanswer") { |e| a << e.text.strip } }
      expect(rt).to eq orig
    end
  end

  context "CSV → XML → CSV: 出力CSVが入力CSVと一致する" do
    it "一致する" do
      xml_str = csv2tsume_convert(CSV_PATH)
      Tempfile.create(["roundtrip", ".xml"], encoding: "UTF-8") do |tmp|
        tmp.write(xml_str)
        tmp.flush
        back_to_csv = tsume2csv_convert(tmp.path)
        expect(back_to_csv.gsub("\r\n", "\n")).to eq File.read(CSV_PATH, encoding: "BOM|UTF-8").gsub("\r\n", "\n")
      end
    end
  end
end
