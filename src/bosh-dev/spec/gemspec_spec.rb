require 'spec_helper'
require 'rubygems/package'

module Bosh::Dev
  describe 'gem' do
    let(:name) { 'bosh-dev' }
    let(:spec) { Gem::Specification.load "#{name}.gemspec" }

    it 'validates' do
      Gem::DefaultUserInteraction.use_ui(Gem::SilentUI.new) do
        expect(spec.validate).to be_truthy
      end
    end
  end
end
