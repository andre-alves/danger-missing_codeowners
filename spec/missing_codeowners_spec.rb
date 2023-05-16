# frozen_string_literal: true

require File.expand_path("spec_helper", __dir__)

module Danger
  describe Danger::DangerMissingCodeowners do
    it "should be a plugin" do
      expect(Danger::DangerMissingCodeowners.new(nil)).to be_a Danger::Plugin
    end

    describe "with Dangerfile" do
      before do
        @dangerfile = testing_dangerfile
        @my_plugin = @dangerfile.missing_codeowners
        @my_plugin.verbose = true
      end

      context "and valid CODEOWNERS file" do
        before do
          allow(@my_plugin).to receive(:find_codeowners_file)
            .and_return("#{File.dirname(__FILE__)}/fixtures/CODEOWNERS")
        end

        it "fails when there are modified files without CODEOWNERS rules and severity is error" do
          allow(@my_plugin).to receive(:git_modified_files)
            .and_return([
                          "app/source.swift",
                          ".swiftlint.yml",
                          "configs/header.xml",
                          "configs/nested/header.xml",
                          "project/configs/header.xml",
                          "docs/index.md",
                          "docs/projects/index.md",
                          "widgets/a/Sources/file.java",
                          "widgets/b/Sources/file.java",
                          "widgets/Sources/file.java",
                          "widgets/a/Tests/file.java",
                          "widgets/Tests/file.java",
                          "path with spaces/ok.php",
                          "path with spaces2/missing.php",
                          "sources/#file_with_pound.rb",
                          "sources/#file_with_pound2.rb",
                          "very/nested/dir/foo/bar/something.swift",
                          "very/nested/foo/bar/something/something.swift",
                          "nested/feature/something.swift",
                          "nested/feature/something/something.swift",
                          "module/LICENSE",
                          "module/README",
                          "nested/lib/source.js",
                          "very/nested/lib/source.js",
                          "very/nested/sources/php/source.php",
                          "model/db/",
                          "sources/something.go"
                        ])

          @my_plugin.verify

          markdown = @dangerfile.status_report[:markdowns].first.to_s
          expect(markdown).to include("app/source.swift")
          expect(markdown).to include("project/configs/header.xml")
          expect(markdown).to include("path with spaces2/missing.php")
          expect(markdown).to include("docs/projects/index.md")
          expect(markdown).to include("widgets/a/Tests/file.java")
          expect(markdown).to include("widgets/Tests/file.java")
          expect(markdown).to include("sources/#file_with_pound2.rb")
          expect(@my_plugin.files_missing_codeowners.length).to eq(7)
          expect(@dangerfile.status_report[:errors]).to eq(["Add CODEOWNERS rules to match all files."])
        end

        it "succeeds when all modified files have CODEOWNERS rules" do
          allow(@my_plugin).to receive(:git_modified_files).and_return(["any_file.yml", "any_file.go"])

          @my_plugin.verify

          expect(@my_plugin.files_missing_codeowners.length).to eq(0)
        end

        it "fails when there are files without CODEOWNERS rules and severity is error" do
          @my_plugin.verify_all_files = true
          allow(@my_plugin).to receive(:git_all_files).and_return(["app/source.swift", ".swiftlint.yml"])

          @my_plugin.verify

          markdown = @dangerfile.status_report[:markdowns].first.to_s
          expect(markdown).to include("app/source.swift")
          expect(@my_plugin.files_missing_codeowners.length).to eq(1)
          expect(@dangerfile.status_report[:errors]).to eq(["Add CODEOWNERS rules to match all files."])
        end

        it "warns when there are files without CODEOWNERS rules and severity is warning" do
          @my_plugin.verify_all_files = true
          @my_plugin.severity = "warning"
          allow(@my_plugin).to receive(:git_all_files).and_return(["app/source.swift", ".swiftlint.yml"])

          @my_plugin.verify

          markdown = @dangerfile.status_report[:markdowns].first.to_s
          expect(markdown).to include("app/source.swift")
          expect(@my_plugin.files_missing_codeowners.length).to eq(1)
          expect(@dangerfile.status_report[:warnings]).to eq(["Add CODEOWNERS rules to match all files."])
        end

        it "succeeds when all files have CODEOWNERS rules" do
          @my_plugin.verify_all_files = true
          allow(@my_plugin).to receive(:git_all_files).and_return(["any_file.yml", "any_file.go"])

          @my_plugin.verify

          expect(@my_plugin.files_missing_codeowners.length).to eq(0)
        end

        it "does not truncates the markdown when there are not too many files missing owners" do
          @my_plugin.max_number_of_files_to_report = 3
          allow(@my_plugin).to receive(:git_modified_files).and_return(["a.xml", "b.xml", "c.xml"])

          @my_plugin.verify

          expect(@dangerfile.status_report[:markdowns].first.to_s).to_not include("other files")
          expect(@my_plugin.files_missing_codeowners.length).to eq(3)
        end

        it "truncates the markdown when there are too many files missing owners" do
          @my_plugin.max_number_of_files_to_report = 1
          allow(@my_plugin).to receive(:git_modified_files).and_return(["a.xml", "b.xml", "c.xml"])

          @my_plugin.verify

          expect(@dangerfile.status_report[:markdowns].first.to_s).to include("2 other files")
          expect(@my_plugin.files_missing_codeowners.length).to eq(3)
        end

        it "verifies added/modified/renamed files correctly when verify_all_files is false" do
          @my_plugin.verify_all_files = false

          allow(@my_plugin.git).to receive(:modified_files).and_return(["file_renamed_to_something_else.swift", "modified_file.swift"])
          allow(@my_plugin.git).to receive(:renamed_files).and_return([{ before: "file_renamed_to_something_else.swift", after: "renamed_file.swift" }])
          allow(@my_plugin.git).to receive(:added_files).and_return(["added_file.swift"])
          allow(@my_plugin.git).to receive(:deleted_files).and_return(["deleted_file.swift"])

          @my_plugin.verify

          expect(@my_plugin.files_missing_codeowners).to include("added_file.swift")
          expect(@my_plugin.files_missing_codeowners).to include("modified_file.swift")
          expect(@my_plugin.files_missing_codeowners).to include("renamed_file.swift")
          expect(@my_plugin.files_missing_codeowners.length).to eq(3)
        end

        it "verifies only the provided files" do
          @my_plugin.verify_all_files = true

          allow(@my_plugin.git).to receive(:added_files).and_return(["added_file.swift"])

          @my_plugin.verify(["added_file2.swift"])

          expect(@my_plugin.files_missing_codeowners).to include("added_file2.swift")
          expect(@my_plugin.files_missing_codeowners.length).to eq(1)
        end

        it "ignores explicitly ignored files" do
          allow(@my_plugin).to receive(:git_modified_files).and_return(["ignored_file.swift", "added_file.swift"])

          @my_plugin.verify(ignored_files: ["ignored_file.swift"])

          expect(@my_plugin.files_missing_codeowners).to include("added_file.swift")
          expect(@my_plugin.files_missing_codeowners.length).to eq(1)
        end
      end

      context "and invalid CODEOWNERS file" do
        before do
          allow(@my_plugin).to receive(:find_codeowners_file)
            .and_return("#{File.dirname(__FILE__)}/fixtures/INVALID_CODEOWNERS")
        end

        it "raises exception with invalid line" do
          allow(@my_plugin).to receive(:git_modified_files).and_return(["any_file.yml", "any_file.go"])

          expect { @my_plugin.verify }.to raise_error(RuntimeError)
        end
      end
    end
  end
end
