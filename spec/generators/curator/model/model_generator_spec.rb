require 'spec_helper'
require 'rails/generators/curator/model/model_generator'

describe Curator::Generators::ModelGenerator do
  destination File.expand_path("../../../../../tmp", __FILE__)

  before { prepare_destination }

  describe 'the generated files' do
    before do
      run_generator %w(note id title description user_id)
    end

    describe 'the model' do
      subject { file('app/models/note.rb') }

      it { should exist }
      it { should contain(/include Curator::Model/) }
      it { should contain(/attr_accessor :id, :title, :description, :user_id/) }
    end
  end
end
