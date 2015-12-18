require 'spec_helper'

describe WikiCloth::Parser do

  describe 'images' do
    it 'renders an image' do
      html = render_md("[[Image:test.jpg]]")

      expect(html).to include("test.jpg")
    end
  end

  describe 'font attributes' do

    it 'has nested italic and bold' do
      html = render_md("''Mars goes around the Sun once in a Martian '''year''', or 1.88 Earth '''years'''.''")

      expect(html).to include("<i>Mars goes around the Sun once in a Martian <b>year</b>, or 1.88 Earth <b>years</b>.</i>")
    end

    it 'has italic' do
      html = render_md("''Mars goes around the Sun once in a Martian year''")

      expect(html).to include("<i>Mars goes around the Sun once in a Martian year</i>")
    end

    it 'has bold' do
      html = render_md("'''Mars goes around the Sun once in a Martian year'''")

      expect(html).to include("<b>Mars goes around the Sun once in a Martian year</b>")
    end

  end

  describe 'math tag' do

    it 'renders' do
      html = render_md("<math>1+1=2</math>")

      expect(html).to include("https://chart.googleapis.com/chart")
    end

    it 'renders even if invalid' do
      html = render_md("<math>1+////1=2</math>")

      expect(html).to include("https://chart.googleapis.com/chart")
    end

  end

  describe 'pluralize' do

    it 'singularizes' do
      html = render_md("{{plural:1|is|are}}")

      expect(html =~ /is/).to be_truthy
    end

    it 'pluralizes' do
      html = render_md("{{plural:2|is|are}}")

      expect(html =~ /are/).to be_truthy
    end

    it 'pluralizes with expresion' do
      html = render_md("{{plural:14/2|is|are}}")

      expect(html =~ /are/).to be_truthy
    end

    it 'singularizes with expression' do
      html = render_md("{{plural:14/2-6|is|are}}")

      expect(html =~ /is/).to be_truthy
    end

  end

  describe 'parser function on multiple lines' do

    it 'renders' do
      html = render_md("{{
      #if:
      |hello world
      |{{
        #if:test
        |boo
        |
        }}
      }}")

      expect(html =~ /boo/).to be_truthy
    end
    
  end

  describe 'tables' do

    it 'renders' do
      html = render_md("
{|
! Predicate
! Subject
|-
|Hello
|World
|}
      ")

      expect(html).to include("Hello")
      expect(html).to include("World")
      expect(html).to include('<table')
      expect(html).to include('</table>')
    end

  end

  describe 'links' do

    it 'renders a link with line breaks' do
      html = render_md("\n\n\nhttp://www.google.com/")

      expect(html).to include('<a href="http://www.google.com/">')
    end

    it 'renders a link until space' do
      html = render_md("hello http://www.google.com/ world")

      expect(html).to include('<a href="http://www.google.com/">')
    end

    it 'renders a link' do
      html = render_md("http://www.google.com/")

      expect(html).to include('<a href="http://www.google.com/">')
    end

    it 'renders a markdown link' do
      html = render_md("[https://github.com/repo/README.md README]")

      expect(html).to include('https://github.com/repo/README.md')
      expect(html =~ /\>\s*README\s*\</).to be_truthy
    end

  end

end
