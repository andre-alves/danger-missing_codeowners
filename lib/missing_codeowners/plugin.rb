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

    # Verifies files for missing owners.
    # Generates a `markdown` list of warnings for the prose in a corpus of
    # .markdown and .md files.
    #
    # @param   [String] files
    #          The list of files you want to verify, defaults to nil.
    #          if nil, modified and added files from the diff will be used.
    #
    # @return  [void]
    #
    def verify(files = nil)
      @verify_all_files ||= false
      @max_number_of_files_to_report ||= 100
      @severity ||= "error"
      @verbose ||= false

      files_to_verify = files || files_from_git

      log "Files to verify:"
      log files_to_verify.join("\n")

      codeowners_path = find_codeowners_file
      codeowners_lines = read_codeowners_file(codeowners_path)
      codeowners_spec = parse_codeowners_spec(codeowners_lines)
      @files_missing_codeowners = files_to_verify.reject { |file| codeowners_spec.match file }

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

    def files_from_git
      @verify_all_files == true ? git_all_files : git_modified_files
    end

    def git_modified_files
      # This algorithm detects added files, modified files and renamed/moved files
      renamed_files_hash = git.renamed_files.map { |rename| [rename[:before], rename[:after]] }.to_h
      post_rename_modified_files = git.modified_files.map { |modified_file| renamed_files_hash[modified_file] || modified_file }
      (post_rename_modified_files - git.deleted_files) + git.added_files
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

          # There is a different between .gitignore spec and CODEOWNERS in regards to nested directories
          # See frotz/ example in https://git-scm.com/docs/gitignore
          # foo/bar (CODEOWNERS) == **/foo/bar (.gitignore)
          if pattern.match(%r{^[^/*].*/.+})
            pattern = "**/#{pattern}"
          end

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
