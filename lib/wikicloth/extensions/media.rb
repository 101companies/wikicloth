require 'cgi'
require 'net/http'
require 'nokogiri'
require 'json'

module WikiCloth
  class MediaExtension < Extension

    module SlideshareService
      Response = Struct.new(:embed, :download_link)

      class << self

        def get_slides(url)
          data = request_data(url)
          response = parse_network_response(data)
          if failed_response?(response)
            return nil
          end
          extract_data(response)
        rescue StandardError
          nil
        end

        private

        def failed_response?(response)
          response.root.name == 'SlideShareServiceError'
        end

        def extract_data(data)
          embed = data.root.xpath("Embed").text
          download_link = data.root.xpath("DownloadUrl").text

          Response.new(embed, download_link)
        end

        def request_data(url)
          timestamp = Time.now.to_i.to_s
          params_string = "?slideshow_url=#{url}&api_key=#{ENV["SLIDESHARE_API_KEY"]}"+
              "&hash=#{Digest::SHA1.hexdigest(ENV["SLIDESHARE_API_SECRET"] + timestamp)}&ts=#{timestamp}"

          uri = URI("https://www.slideshare.net/api/2/get_slideshow#{params_string}")
          Net::HTTP.get(uri)
        end

        def parse_network_response(data)
          Nokogiri.XML(data)
        end

      end
    end

    def get_slideshare_slide(url)
      # do api request to slideshare and parse retrieved xml
      if !ENV['SLIDESHARE_API_KEY']
        return WikiCloth::error_template "Failed to retrieve slides"
      end

      response = SlideshareService.get_slides(url)
      return WikiCloth::error_template "Failed to retrieve slides" if response.nil?
      # retrieve embed and download link from response

      # prepare special link for rails app
      if response.download_link.present?
        app_download_link ="<a target='_blank' href='/get_slide/#{CGI.escape(url)}' download-link='#{response.download_link}'>"+
          "<i class='icon-download-alt'></i> Download slides</a>"
      end
      # retrieved embed
      if response.embed
        "<div class='slideshare-slide'>#{response.embed}<p>#{(defined? app_download_link) ? app_download_link : ''}</p></div>"
      else
        WikiCloth::error_template "Failed to retrieve slides"
      end
    end

    # return youtube id or nil
    def get_youtube_video_id(url)
      # find id
      result = url.match /https*\:\/\/.*youtube\.com\/watch\?v=(.*)/
      # return id or nil
      result ? result[1] : nil
    end

    # retrieve youtube embed by youtube id
    def get_youtube_video(id)
      uri = URI("https://noembed.com/embed?url=https://www.youtube.com/watch?v=#{id}")
      begin
        resp_body = Net::HTTP.get(uri)
        title = JSON.parse(resp_body)['title']
      rescue
        title = "Title wasn't found"
      end
      # render html for youtube video embed
      "<div class='video-title'>#{title}</div><iframe width='420' frameborder='0' height='315'"+
        " src='https://www.youtube-nocookie.com/embed/#{id.to_s}' allowfullscreen></iframe>"
    end

    element 'media', :skip_html => true, :run_globals => false do |buffer|
      result = WikiCloth::error_template 'No media information was retrieved'
      media_url = buffer.get_attribute_by_name "url"
      if media_url
        # Youtube: <media url="http://www.youtube.com/watch?v=[_ID_]">
        # try to retrieve youtube video from media-tag
        youtube_id = get_youtube_video_id media_url
        if youtube_id
          result = get_youtube_video(youtube_id)
        end
        # Slideshare: <media url="[_SLIDESHARE_URL_]">
        # try to retrieve slideshare slide from media-tag
        result = (get_slideshare_slide media_url) if media_url.match /https*\:\/\/.*slideshare\.net/
      end
      result
    end
  end
end
