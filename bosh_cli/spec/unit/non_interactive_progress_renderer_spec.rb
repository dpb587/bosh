require 'spec_helper'

describe 'NonInteractiveProgressRenderer' do

  let(:renderer){ Bosh::Cli::NonInteractiveProgressRenderer.new }
  let(:label) { "foo" }
  let(:error) { "an error" }

  context 'when there is a single active task' do
    let(:path) { "/task/0" }

    it 'renders initial progress' do
      expect_render(path, label, renderer)
      renderer.start(path, label)
    end

    it 'does not render subsequent progress' do

      expect(renderer).to_not receive(:say)
    end

    it 'renders error' do
      expect_render(path, error, renderer)
      renderer.error(path, error)
    end

    it 'renders finished' do
      expect_render(path, label, renderer)
      renderer.finish(path, label)
    end
  end

  context 'when there are multiple active downloads' do
    let(:path1) { "/task/0" }
    let(:path2) { "/task/1" }
    let(:path3) { "/task/2" }

    it 'renders initial progress' do
      expect_render(path1, label, renderer)
      renderer.start(path1, label)

      expect_render(path2, label, renderer)
      renderer.start(path2, label)

      expect_render(path3, label, renderer)
      renderer.start(path3, label)
    end

    it 'does not render subsequent progress' do

      expect(renderer).to_not receive(:say)

    end

    it 'renders error' do


      expect_render(path1, error, renderer)
      renderer.error(path1, error)
      expect_render(path2, error, renderer)
      renderer.error(path2, error)
      expect_render(path3, error, renderer)
      renderer.error(path3, error)
    end

    it 'renders finished' do


      expect_render(path1, label, renderer)
      renderer.finish(path1, label)
      expect_render(path2, label, renderer)
      renderer.finish(path2, label)
      expect_render(path3, label, renderer)
      renderer.finish(path3, label)
    end
  end
end

def expect_render(path, label, renderer)
  expect(path).to receive(:truncate).and_return(path)
  expect(renderer).to receive(:say).with("#{path} #{label}")
end
