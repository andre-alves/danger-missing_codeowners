# frozen_string_literal: true

require "pathspec"

module Danger
  # Parses the CODEOWNERS file and verifies if files have at least one owner.
  # Works with GitHub and GitLab.
  # Results are passed out as a table in markdown.
  #
  # @example Verifying files missing codeowners.
  #
  #          missing_codeowners.verify
  #
  # @see  andre-alves/danger-missing_codeowners
  # @tags codeowners
  #
  class DangerMissingCodeowners < Plugin
    # The list of files that are missing owners.
    #
    # @return   [Array<String>]
    attr_accessor :files_missing_codeowners

    # Whether all files or only ones in PR diff to be reported. Default is false.
    #
    # @return   [Bool]
    attr_accessor :verify_all_files

    # The maximum number of files missing owners Danger should report. Default is 100.
    #
    # @return   [Int]
    attr_accessor :max_number_of_files_to_report

    # Defines the severity level of the execution. Possible values are: 'error' or 'warning'. Default is 'error'.
    #
    # @return   [String]
    attr_accessor :severity

    # Provides additional logging diagnostic information. Default is false.
    #
    # @return   [Bool]
    attr_accessor :verbose

    # Verifies git added and modified files for missing owners.
    # Generates a `markdown` list of warnings for the prose in a corpus of
    # .markdown and .md files.
    #
    # @return  [void]
    #
    def verify
      @verify_all_files ||= false
      @max_number_of_files_to_report ||= 100
      @severity ||= "error"
      @verbose ||= false

      files = files_to_verify
      log "Files to verify:"
      log files.join("\n")

      codeowners_path = find_codeowners_file
      codeowners_lines = read_codeowners_file(codeowners_path)
      codeowners_spec = parse_codeowners_spec(codeowners_lines)
      @files_missing_codeowners = files.reject { |file| codeowners_spec.match file }

      if @files_missing_codeowners.any?
        log "Files missing CODEOWNERS:"
        log @files_missing_codeowners.join("\n")

        markdown format_missing_owners_message(@files_missing_codeowners, @max_number_of_files_to_report)
        danger_message = "Add CODEOWNERS rules to match all files."
        @severity == "error" ? (fail danger_message) : (warn danger_message)
      else
        log "No files missing CODEOWNERS."
      end

      log "-----"
    end

    private

    def files_to_verify
      @verify_all_files == true ? git_all_files : git_modified_files
    end

    def git_modified_files
      git.added_files + git.modified_files
    end

    def git_all_files
      # The git object provided by Danger doesn't have ls_files
      `git ls-files`.split($/)
    end

    def find_codeowners_file
      directories = ["", ".gitlab", ".github", "docs"]
      paths = directories.map { |dir| File.join(dir, "CODEOWNERS") }
      Dir.glob(paths).first || paths.first
    end

    def read_codeowners_file(path)
      log "Reading the CODEOWNERS file from path: #{path}"
      File.readlines(path).map(&:chomp)
    end

    def parse_codeowners_spec(lines)
      patterns = []
      lines.each do |line|
        components = line.split(/\s+(@\S+|\S+@\S+)/).reject { |c| c.strip.empty? }
        if line.match(/^\s*((?:#.*)|(?:\[.*)|(?:\^.*))?$/)
          next # Comment, group or empty line
        elsif components.length < 2
          raise "[ERROR] Invalid CODEOWNERS line: '#{line}'"
        else
          pattern = components[0]
          patterns << pattern
          log "Adding pattern: '#{pattern}'"
        end
      end
      PathSpec.from_lines(patterns)
    end

    def format_missing_owners_message(files, max_count)
      message = "### Files missing CODEOWNERS\n\n".dup
      message << "| File |\n"
      message << "| ---- |\n"
      files.take(max_count).each do |file|
        message << "| #{file} |\n"
      end

      other_files_length = files.length - max_count
      if other_files_length.positive?
        message << "...and #{other_files_length} other files.\n"
      end

      message
    end

    def log(text)
      puts(text) if @verbose
    end
  end
end
