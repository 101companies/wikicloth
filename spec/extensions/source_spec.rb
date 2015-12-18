require 'spec_helper'

describe 'Source' do

  it 'renders source file' do
    html = render_md('<syntaxhighlight lang="python" source="101companies.py">
              @t(Employee)
              def salary(e):
                  return e.salary

              total = everything(operator.add, 0 |mkQ| salary)
            </syntaxhighlight>')

    expect(html).to include('@t')
    expect(html).to include('salary')
    expect(html).to include('Employee')
  end

  it 'renders source file' do
    html = render_md('<syntaxhighlight lang="python" source="101companies.py">
              @t(Employee)
              def salary(e):
                  return e.salary

              total = everything(operator.add, 0 |mkQ| salary)
            </syntaxhighlight>')

    html2 = render_md('<syntaxhighlight language="python" source="101companies.py">
              @t(Employee)
              def salary(e):
                  return e.salary

              total = everything(operator.add, 0 |mkQ| salary)
            </syntaxhighlight>')

    expect(html).to eq(html2)
  end

  it 'gets an unkown language' do
    html = render_md('<syntaxhighlight lang="this-is-not-python" source="101companies.py">
            @t(Employee)
            def salary(e):
                return e.salary

            total = everything(operator.add, 0 |mkQ| salary)
          </syntaxhighlight>')

    expect(html).to include("<p><div class='error'>Invalid Language supplied</div></p>")
  end

  it 'gets invalid source but still parses and does not fail' do
    html = render_md('<syntaxhighlight lang="python" source="101companies.py">
            class X { render() { return <div></div>; } }
          </syntaxhighlight>')

    expect(html).to include('return')
    expect(html).to include('render')
  end

end
