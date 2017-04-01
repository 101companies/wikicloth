require 'spec_helper'

describe 'media' do

  describe 'slideshare' do

    it 'renders slideshare' do
      ENV['SLIDESHARE_API_KEY'] = 'something'
      ENV['SLIDESHARE_API_SECRET'] = 'something else'

      allow(WikiCloth::MediaExtension::SlideshareService).to receive(:get_slides) do
        WikiCloth::MediaExtension::SlideshareService::Response.new('some text', 'some text')
      end

      html = render_md('<media url="http://www.slideshare.net/rlaemmel/rmi-23850462"/>')

      expect(html).to include("<p><div class='slideshare-slide'>some text<p><a target='_blank' href='/get_slide/http%3A%2F%2Fwww.slideshare.net%2Frlaemmel%2Frmi-23850462' download-link='some text'><i class='icon-download-alt'></i> Download slides</a></p></div></p>")
    end

  end

  describe 'youtube' do

    it 'renders youtube' do
      html = render_md('<media url=" https://www.youtube.com/watch?v=C5AWbFeJcTQ" />')

      expect(html).to include('Simple algorithms in Haskell')
    end

  end

end
