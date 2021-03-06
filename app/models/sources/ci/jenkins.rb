require 'open-uri'

module Sources
  module Ci
    class Jenkins < Sources::Ci::Base

      def fields
        [
          { :name => "server_url", :title => "Server Url", :mandatory => true },
          { :name => "project", :title => "Project", :mandatory => true },
        ]
      end

      # Returns ruby hash:
      def get(options = {})
        fields = options.fetch(:fields)
        result = request_build_status(fields.fetch(:server_url), fields.fetch(:project))
        # older jenkins version don't return application/json as Content-Type, 
        # we need to parse it explicitly
        result = JSON.parse(result) rescue result
        {
          :label             => result["fullDisplayName"],
          :last_build_time   => result["lastBuildTime"],
          :last_build_status => status(result["result"]),
          :current_status    => current_status(result["building"])
        }
      end

      def request_build_status(server_url, project)
        url = "#{server_url}/job/#{project}/lastBuild/api/json"
        Rails.logger.debug("Requesting from #{url} ...")
        ::HttpService.request(url)
      end

      def status(status)
        case status
        when /success/i
          0
        when /failure/i
          1
        else
          -1
        end
      end

      def current_status(building)
        return -1 if building.nil?
        building  ? 1 : 0
      end

    end
  end
end
