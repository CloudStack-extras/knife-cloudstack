module KnifeCloudstack
  module Helpers
    def locate_config_value(key)
      key = key.to_sym
      Chef::Config[:knife][key].nil? ? config[key] : Chef::Config[:knife][key]
    end
  end
end
