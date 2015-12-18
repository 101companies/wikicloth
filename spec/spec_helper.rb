require 'simplecov'
SimpleCov.start

require_relative '../init'

include WikiCloth

module WikiClothHelpers

  def render_md(text, context: {})
    WikiCloth::Parser.context = context
    wiki = WikiCloth::Parser.new({
      data: text
    })
    wiki.to_html
  end

end

RSpec.configure do |config|

  config.include(WikiClothHelpers)

end
