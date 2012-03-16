require 'spec_helper'
require 'rails/generators/curator/repository/repository_generator'

describe Curator::Generators::RepositoryGenerator do
  destination TMP_PATH

  before { prepare_destination }
  after { FileUtils.rm_r TMP_PATH }

  describe 'the generated files' do
    before do
      run_generator %w(note user_id)
    end

    describe 'the repository' do
      subject { file('app/repositories/note.rb') }

      it { should exist }
      it { should contain(/class NoteRepository/) }
      it { should contain(/include Curator::Repository/) }
      it { should contain(/indexed_fields :user_id/) }
    end
  end
end
