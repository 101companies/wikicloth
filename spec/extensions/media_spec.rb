require 'spec_helper'

describe 'media' do

  describe 'slideshare' do

    it 'renders slideshare' do
      html = render_md('<media url="http://www.slideshare.net/rlaemmel/rmi-23850462"/>')

      expect(html).to include('<iframe src="https://www.slideshare.net/slideshow/embed_code/key/afKVTRPAku4UjC"')
      expect(html).to include('Remote method invocation (as part of the the PTT lecture)')
    end

  end

  describe 'youtube' do

    it 'renders youtube' do
      html = render_md('<media url=" https://www.youtube.com/watch?v=C5AWbFeJcTQ" />')

      expect(html).to include('Simple algorithms in Haskell')
    end

  end

end
