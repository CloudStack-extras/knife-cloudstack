module KnifeCloudstack
  module Helpers
    def locate_config_value(key)
      key = key.to_sym
      Chef::Config[:knife][key].nil? ? config[key] : Chef::Config[:knife][key]
    end

    def connection
      @connection ||= CloudstackClient::Connection.new(
        locate_config_value(:cloudstack_url),
        locate_config_value(:cloudstack_api_key),
        locate_config_value(:cloudstack_secret_key),
        locate_config_value(:cloudstack_project),
        locate_config_value(:use_http_ssl)
      )
    end
  end
end
