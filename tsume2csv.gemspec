# frozen_string_literal: true

require_relative "lib/tsume2csv/version"

Gem::Specification.new do |spec|
  spec.name = "tsume2csv"
  spec.version = Tsume2csv::VERSION
  spec.authors = ["ISHIKAWA Takayuki"]
  spec.email = ["topstone@users.noreply.github.com"]

  spec.summary     = "Convert between Moodle XML (qtype_tsumeshogi) and CSV"
  spec.description = <<~DESC
    Two command-line tools for the Moodle qtype_tsumeshogi question type:
      tsume2csv  converts a Moodle XML export file to CSV.
      csv2tsume  converts a CSV file to a Moodle-importable XML file.
    CSV columns: name, questiontext (plain), generalfeedback (plain), correctanswer (USI), sfen.
  DESC
  spec.homepage = "https://github.com/topstone/tsume2csv"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 4.0.0"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/topstone/tsume2csv"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Uncomment the line below to require MFA for gem pushes.
  # This helps protect your gem from supply chain attacks by ensuring
  # no one can publish a new version without multi-factor authentication.
  # See: https://guides.rubygems.org/mfa-requirement-opt-in/
  # spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/ .rubocop.yml])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "csv", ">= 3.2"
  spec.add_dependency "rexml", ">= 3.2"
  spec.add_development_dependency "irb"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rubocop"

  # For more information and examples about making a new gem, check out our
  # guide at: https://guides.rubygems.org/make-your-own-gem/
end
