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

        it "fails when there are added or changed files without CODEOWNERS rules" do
          allow(@my_plugin.git).to receive(:added_files)
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
                          "path with spaces2/missing.php"
                        ])
          allow(@my_plugin.git).to receive(:modified_files)
            .and_return([
                          "sources/#file_with_pound.rb",
                          "sources/#file_with_pound2.rb",
                          "module/README",
                          "nested/lib/source.js",
                          "lib/source.js",
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
          expect(@dangerfile.status_report[:errors]).to eq(["Add CODEOWNERS rules to all added and changed files."])
        end

        it "succeeds when all added and changed files have CODEOWNERS rules" do
          allow(@my_plugin.git).to receive(:added_files).and_return(["any_file.yml"])
          allow(@my_plugin.git).to receive(:modified_files).and_return(["any_file.go"])

          @my_plugin.verify

          expect(@my_plugin.files_missing_codeowners.length).to eq(0)
        end
      end

      context "and invalid CODEOWNERS file" do
        before do
          allow(@my_plugin).to receive(:find_codeowners_file)
            .and_return("#{File.dirname(__FILE__)}/fixtures/INVALID_CODEOWNERS")
        end

        it "raises exception with invalid line" do
          allow(@my_plugin.git).to receive(:added_files).and_return(["any_file.yml"])
          allow(@my_plugin.git).to receive(:modified_files).and_return(["any_file.go"])

          expect { @my_plugin.verify }.to raise_error(RuntimeError)
        end
      end
    end
  end
end
