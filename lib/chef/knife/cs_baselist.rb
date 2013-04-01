#
# Author:: Sander Botman (<sbotman@schubergphilis.com>)
# Copyright:: Copyright (c) 2013 Sander Botman.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'chef/knife'

class Chef
  class Knife
    module KnifeCloudstackBaseList

      def self.included(includer)
        includer.class_eval do

          option :filter,
                 :long => "--filter 'FIELD:NAME'",
                 :description => "Specify field and part of name to list"

          option :fields,
                 :long => "--fields 'NAME, NAME'",
                 :description => "The fields to output, comma-separated"

          option :fieldlist,
                 :long => "--fieldlist",
                 :description => "The available fields to output/filter",
                 :boolean => true

          option :noheader,
                 :long => "--noheader",
                 :description => "Removes header from output",
                 :boolean => true
        end
      end

      def list_object_fields(object)
        exit 1 if object.nil? || object.empty?
        object_fields = [
          ui.color('Key', :yellow, :bold),
          ui.color('Type', :yellow, :bold),
          ui.color('Value', :yellow, :bold)
        ]

        object.first.sort.each do |k,v|
          object_fields << k
          object_fields << v.class.to_s
          if v.kind_of?(Array)
            object_fields << '<Array>'
          else
            object_fields << ("#{v}").strip.to_s
          end
        end
        puts "\n"
        puts ui.list(object_fields, :uneven_columns_across, 3)
      end
    
    end
  end
end
