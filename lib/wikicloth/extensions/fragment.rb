require 'pygments.rb'
require 'net/http'
require 'json'
require 'active_support/inflector'

module WikiCloth

  class FragmentError < StandardError
    def initialize(message = 'Internal error: 500')
      super
    end
  end

  class FragmentExtension < Extension

    def buildUrl(url)
      resource_prefix = "http://worker.101companies.org/services/discovery/"

      #absolute path -- keep it as is
      if url.start_with?("http://worker.101companies.org/services/discovery/")
        return url
      end

      # another case, when url already has title and namespace
      if url.start_with?("/contributions") || url.start_with?("/concepts") || url.start_with?("/languages")
        # remove slash
        url[0] = ''
        return resource_prefix + url
      end

      # retrieve namespace and title
      ns = Parser.context[:ns]
      title = Parser.context[:title]

      # TODO: other escaping methods?
      title.gsub!(' ', '_')

      # if starts with '/' -> already has title
      if url.start_with?("/")
        query_title = url
      # else add the title to url
      else
        query_title = title + '/' + url
      end

      resource_prefix + ns.downcase.pluralize + '/' + query_title

    end

    def get_json(url)
      begin
        url = URI.parse(url)
        request = Net::HTTP::Get.new url
        response = Net::HTTP.start(url.host, url.port, read_timeout: 0.5, connect_timeout: 1) {|http| http.request(request)}

        if response.code == '500' || response.code == '404'
          raise FragmentError, 'Retrieved empty json from discovery service'
        end
        JSON.parse(response.message)
      rescue JSON::ParserError, Timeout::Error, Errno::EHOSTUNREACH, Errno::EINVAL, Errno::ECONNREFUSED, Errno::ECONNRESET, EOFError, Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError => e
        raise FragmentError, 'Discovery Service unavailable'
      end
    end

    # <fragment>
    # ....
    # </fragment>
    element 'fragment', :skip_html => true, :run_globals => false do |buffer|
      error = nil

      begin
        raise FragmentError, I18n.t("url attribute is required") unless buffer.element_attributes.has_key?('url')

        ns = Parser.context[:ns].downcase.pluralize || 'Concept'
        title = Parser.context[:title]
        fragment = buffer.element_attributes['url'].split('/')

        url = buildUrl(buffer.element_attributes['url'])

        if fragment.length == 1
          file = fragment
          fragment = []
        else
          file = fragment.take_while { |s| !s.include?('.') }
          file += [fragment[file.length]]
          fragment = fragment.drop(file.length)
        end

        path = "~/101web/data/resources/#{ns}/#{title}/#{file.join('/')}.extractor.json"
        path = File.expand_path(path)

        if File.exists?(path)
          content = File.read(path)
          data = JSON::parse(content)
        else
          data = {
            'imports' => [],
            'fragments' => []
          }
        end

        def find_fragment(query, data)
          head = query.take(2)
          tail = query.drop(2)


          data.each do |f|
            if f['classifier'] == head[0] && f['name'] == head[1]
              if tail.length > 0
                data = f['fragments']
                return find_fragment(tail, data)
              else
                return f
              end
            end
          end

          []
        end

        if fragment.length > 0
          json = find_fragment(fragment, data['fragments'])

          if json.length == 0
            raise FragmentError, 'Fragment not found'
          end

          path = "~/101results/101repo/#{ns}/#{title}/#{file.join('/')}"
          path = File.expand_path(path)

          if !File.exists?(path)
            raise FragmentError, 'Fragment not found'
          end
          content = File.read(path).lines.map(&:chomp)
          content = content[json['startLine']-1..json['endLine']-1].join("\n")

          path = "~/101web/data/resources/#{ns}/#{title}/#{file.join('/')}.lang.json"
          lang = JSON::parse(File.read(File.expand_path(path)), quirks_mode: true)

          content = Pygments.highlight(content, :lexer => lang.downcase)
        else
          path = "~/101results/101repo/#{ns}/#{title}/#{file.join('/')}"
          path = File.expand_path(path)

          if !File.exists?(path)
            raise FragmentError, 'Fragment not found'
          end
          content = File.read(path)

          path = "~/101web/data/resources/#{ns}/#{title}/#{file.join('/')}.lang.json"
          lang = JSON::parse(File.read(File.expand_path(path)), quirks_mode: true)

          if lang != 'unkown'
            content = Pygments.highlight(content, :lexer => lang.downcase)
          else
            content = "<code>#{content}</code>"
          end
        end

      rescue FragmentError => err
        error = WikiCloth.error_template err.message
      end

      if error.nil?
        content
      else
        error
      end
    end

    # <file>
    # ....
    # </file>
    element 'file', :skip_html => true, :run_globals => false do |buffer|
      error = nil

      begin
        raise FragmentError, I18n.t("url attribute is required") unless buffer.element_attributes.has_key?('url')

        ns = Parser.context[:ns].downcase.pluralize || 'Concept'
        title = Parser.context[:title]
        file = buffer.element_attributes['url']

        path = "~/101results/101repo/#{ns}/#{title}/#{file}"
        lang_path = "~/101web/data/resources/#{ns}/#{title}/#{file}.lang.json"

        path = File.expand_path(path)
        lang_path = File.expand_path(lang_path)

        if !File.exists?(path)
          raise FragmentError, 'Fragment not found'
        end

        content = File.read(path)

        if File.exists?(lang_path)
          lang = JSON::parse(File.read(File.expand_path(lang_path)), quirks_mode: true)

          content = Pygments.highlight(content, lexer: lang.downcase)
        end
      rescue FragmentError => err
        error = WikiCloth.error_template err.message
      end

      if error.nil?
        content
      else
        error
      end

    end

    # <folder>
    # ....
    # </folder>
    element 'folder', :skip_html => true, :run_globals => false do |buffer|
      begin
        raise FragmentError, I18n.t("url attribute is required") unless buffer.element_attributes.has_key?('url')
        url = buildUrl(buffer.element_attributes['url'])
        # if exception thrown in get_json => not found or internal error
        get_json(url)
      rescue FragmentError => err
        error = WikiCloth.error_template err.message
      end

      if error.nil?
        "<a href=\"#{url}?format=html\">#{buffer.element_attributes['url']}</a>"
      else
        error
      end

    end
  end
end
