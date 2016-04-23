require 'pygments.rb'

module WikiCloth
  class SourceExtension < Extension

    VALID_LANGUAGES = [ 'as','applescript','arm','asp','asm','awk','bat','bibtex','bbcode','bison','lua',
      'bms','boo','c','c++','cc','cpp','cxx','h','hh','hpp','hxx','clojure','cbl','cob','cobol','cfc','cfm',
      'coldfusion','csharp','cs','css','d','diff','patch','erlang','erl','hrl','go','hs','haskell','html',
      'htm','xml','xhtml','httpd','js','javascript','matlab','m','perl','cgi','pl','plex','plx','pm','php',
      'php3','php4','php5','php6','python','py','ruby','rb', 'java', 'sql', 'bash']

    # <syntaxhighlight lang="language">source code</syntaxhighlight>
    #
    element 'syntaxhighlight', skip_html: true, run_globals: false do |buffer|
      name = buffer.element_name
      content = buffer.element_content
      content = $1 if content =~ /^\s*\n(.*)$/m
      error = nil
        begin
          raise I18n.t("lang/language attribute is required") unless (buffer.element_attributes.has_key?('lang') or buffer.element_attributes.has_key?('language'))
          if buffer.element_attributes.has_key?('lang')
            lexer = buffer.element_attributes['lang'].downcase
          elsif buffer.element_attributes.has_key?('language')
            lexer = buffer.element_attributes['language'].downcase
          end

          unless VALID_LANGUAGES.include?(lexer)
            raise 'Invalid Language supplied'
          end

          content = Pygments.highlight(content, lexer: lexer)
        rescue => err
          error = WikiCloth.error_template err.message
        end
      if error.nil?
        "#{content}"
      else
        error
      end
    end
  end
end
