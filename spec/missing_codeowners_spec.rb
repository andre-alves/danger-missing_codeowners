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

        fixtures_path = "#{File.dirname(__FILE__)}/fixtures"
        allow(@my_plugin).to receive(:find_codeowners_file).and_return("#{fixtures_path}/CODEOWNERS")

        added_files = File.readlines("#{fixtures_path}/added_files.txt").map(&:chomp)
        allow(@my_plugin.git).to receive(:added_files).and_return(added_files)

        modified_files = File.readlines("#{fixtures_path}/modified_files.txt").map(&:chomp)
        allow(@my_plugin.git).to receive(:modified_files).and_return(modified_files)
      end

      it "Fails when there are added or changed files without CODEOWNERS rules" do
        @my_plugin.verify

        expect(@my_plugin.files_missing_codeowners.length).to eq(2)
        expect(@dangerfile.status_report[:errors]).to eq(["Add CODEOWNERS rules to all added and changed files."])
        markdown = @dangerfile.status_report[:markdowns].first.to_s
        expect(markdown).to include("MyClass.swift")
        expect(markdown).to include("Dir2/NewFile.txt")
      end
    end
  end
end
