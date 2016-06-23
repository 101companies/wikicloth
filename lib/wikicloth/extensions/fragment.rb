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

        file = fragment.take_while { |s| !s.include?('.') }
        file += [fragment[file.length]]
        fragment = fragment.drop(file.length)

        path = "~/101web/data/resources/#{ns}/#{title}/#{file.join('/')}.extractor.json"
        path = File.expand_path(path)

        if File.exists?(path)
          content = File.read(path)
          data = JSON::parse(content)
        else
          ap 'does not exist'
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

        json = find_fragment(fragment, data['fragments'])
        if json.length == 0
          raise FragmentError, 'Retrieved empty json from discovery service'
        end

        path = "~/101results/101repo/#{ns}/#{title}/#{file.join('/')}"
        path = File.expand_path(path)

        content = File.read(path).lines.map(&:chomp)
        content = content[json['startLine']-1..json['endLine']-1].join("\n")


        content = Pygments.highlight(content, :lexer => json['geshi'])
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
        url = buildUrl(buffer.element_attributes['url'])
        json = get_json(url)
        name = json['name']
        content = Pygments.highlight(json['content'], :lexer => json['geshi'])
      rescue FragmentError => err
        error = WikiCloth.error_template err.message
      end

      need_to_show_content = buffer.element_attributes.has_key?('show') && (buffer.element_attributes['show'] == "true")

      # if set user defined name for file fragment
      if buffer.element_attributes.has_key?('name')
        user_defined_name = buffer.element_attributes['name']
        # remove trailing spaces
        user_defined_name.strip!
        # if not empty -> rewrite current param name
        if !user_defined_name.nil? && user_defined_name != ''
          name = user_defined_name
        end
      end

      if error.nil?
        if need_to_show_content
          if content
            "#{content}"
          else
            WikiCloth.error_template 'No content found for file'
          end
        else
          "<a href=\"#{url}?format=html\">#{name}</a>"
        end
      else
        if need_to_show_content
          error
        else
          # if not defined name by user and not retrieved from discovery
          # then define name from filename
          if name.nil?
            require 'pathname'
            name = Pathname.new(buffer.element_attributes['url']).basename
          end
          "<span class='fragment-failed'>#{name}</span>"
        end
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
