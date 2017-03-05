require 'spec_helper'

describe 'fragment' do

  it 'renders a fragment' do
    html = render_md('<fragment url="src/Main.hs/pattern/total"/>', context: { ns: 'Contribution', title: 'haskellStarter' })

    expect(html).to include('sum')
  end

  it 'has invalid title' do
    html = render_md('<fragment url="src/Main.hs/pattern/total"/>',
      context: { ns: 'Contribution', title: 'NotAContribution' }
    )

    expect(html).to include('<div class=\'error\'>Fragment not found</div>')
  end

  it 'renders a file with unkown language' do
    html = render_md('<file url=\'haskellEngineer.cabal\'/>', context: {:ns=>"Contribution", :title=>"haskellEngineer"})

    expect(html).to include('<code>')
  end

  it 'renders a file' do
    html = render_md('<file url=\'HelloWorld.java\'/>', context: { ns: 'Language', title: 'Java' })

    expect(html).to include('<div class="highlight">')
  end

  it 'renders a file with show which does not exist' do
    html = render_md('<file url=\'HelloWorldOrSomething.java\' name=\'Name\' show=\'true\' />', context: { ns: 'Language', title: 'Java' })

    expect(html).to include('<div class=\'error\'>Fragment not found</div>')
  end

  it 'renders a file show which does not exist' do
    html = render_md('<file url=\'HelloWorldOrSomething.java\' name=\'Name\' />', context: { ns: 'Language', title: 'Java' })

    expect(html).to include('<div class=\'error\'>Fragment not found</div>')
  end

end
