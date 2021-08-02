# frozen_string_literal: true

require 'pathspec'

module Danger
  # Reads CODEOWNERS files and checks that all added & modified files have at least one owner.
  # Works with GitHub and GitLab.
  # Results are passed out as a table in markdown.
  #
  # @example Verifying files missing codeowners.
  #
  #          missing_codeowners.verify
  #
  # @tags codeowners
  #
  class DangerMissingCodeowners < Plugin
    # The list of files that are missing owners.
    #
    # @return   [Array<String>]
    attr_accessor :files_missing_codeowners

   # Provides additional logging diagnostic information.
    attr_accessor :verbose

    # Verifies git added and changed files for missing owners.
    # Generates a `markdown` list of warnings for the prose in a corpus of
    # .markdown and .md files.
    #
    # @return  [void]
    #
    def verify
      codeowners_path = find_codeowners_file
      codeowners_lines = read_codeowners_file(codeowners_path)
      codeowners_spec = parse_codeowners_spec(codeowners_lines)
      files = files_to_verify
      @files_missing_codeowners = files.select { |file| !codeowners_spec.match file }

      return if @files_missing_codeowners.empty?

      markdown format_missing_owners_message(@files_missing_codeowners)
      fail 'Add CODEOWNERS rules to all added and changed files.'
    end

    def files_to_verify
      git.added_files + git.modified_files
    end

    def find_codeowners_file
      directories = ['', '.gitlab', '.github', 'docs']
      paths = directories.map { |dir| File.join(dir, 'CODEOWNERS') }
      Dir.glob(paths).first || paths.first
    end

    def read_codeowners_file(path)
      log "Reading CODEOWNERS file from path: #{path}"
      File.readlines(path).map(&:chomp)
    end

    def parse_codeowners_spec(lines)
      patterns = []
      lines.each do |line|
        components = line.split(/\s+@/, 2)
        if !line.match(/^\s*(?:#.*)?$/) && components.length == 2 && !components[0].empty?
          pattern = components[0]
          patterns << pattern
          log "Adding pattern: #{pattern}"
        end
      end
      PathSpec.from_lines(patterns)
    end

    def format_missing_owners_message(files)
      message = "### Files missing CODEOWNERS\n\n".dup
      message << "| File |\n"
      message << "| ---- |\n"
      files.each do |file|
        message << "| #{file} |\n"
      end
      message
    end

   def log(text)
      puts(text) if @verbose
    end
  end
end
