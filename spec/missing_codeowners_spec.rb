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

        allow(@my_plugin).to receive(:find_codeowners_file).and_return("#{File.dirname(__FILE__)}/fixtures/CODEOWNERS")
      end

      it "Fails when there are added or changed files without CODEOWNERS rules" do
        added_files = [
          "swiftlint.yml",
          "Path With Spaces/Dummy.txt",
          "MyClass.swift"
        ]
        modified_files = [
          "File.txt",
          "Dir2/NewFile.txt"
        ]
        allow(@my_plugin.git).to receive(:added_files).and_return(added_files)
        allow(@my_plugin.git).to receive(:modified_files).and_return(modified_files)

        @my_plugin.verify

        expect(@my_plugin.files_missing_codeowners.length).to eq(2)
        expect(@dangerfile.status_report[:errors]).to eq(["Add CODEOWNERS rules to all added and changed files."])
        markdown = @dangerfile.status_report[:markdowns].first.to_s
        expect(markdown).to include("MyClass.swift")
        expect(markdown).to include("Dir2/NewFile.txt")
      end

      it "Succeeds when all added and changed files have CODEOWNERS rules" do
        allow(@my_plugin.git).to receive(:added_files).and_return(["Anyfile.yml"])
        allow(@my_plugin.git).to receive(:modified_files).and_return(["Anyfile.go"])

        @my_plugin.verify

        expect(@my_plugin.files_missing_codeowners.length).to eq(0)
      end
    end
  end
end
