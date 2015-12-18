require 'spec_helper'

describe 'References' do

  describe 'references' do

    it 'renders' do
      html = render_md('<references group="group_name" />')

      expect(html).to include('ol')
    end

  end

  describe 'ref' do

    it 'renders' do
      html = render_md('<ref name="named">reference content</ref>')

      expect(html).to include('<sup class="reference"')
    end

  end

end
