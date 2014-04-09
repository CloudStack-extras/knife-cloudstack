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

require 'json'
require 'chef/knife/cs_base'

class Chef
  class Knife
    module KnifeCloudstackBaseList

      def self.included(includer)
        includer.class_eval do
          include Chef::Knife::KnifeCloudstackBase

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

      def output_format(json)
        if locate_config_value(:format) =~ /^j/i
          json_hash = {};
          json.each { |k| json_hash.merge!( k['id'] => k) }
          puts JSON.pretty_generate(json_hash)
          exit 0
        end
      end

      def list_object_fields(object)
        exit 1 if object.nil? || object.empty?
        object_fields = [
          ui.color('Key', :bold),
          ui.color('Type', :bold),
          ui.color('Value', :bold)
        ]

        object.first.sort.each do |k,v|
          object_fields << ui.color(k, :yellow, :bold)
          object_fields << v.class.to_s
          if v.kind_of?(Hash)
            object_fields << '<Hash>'
          elsif v.kind_of?(Array)
            object_fields << '<Array>'
          else
            object_fields << ("#{v}").strip.to_s
          end
        end
        puts "\n"
        puts ui.list(object_fields, :uneven_columns_across, 3)
      end

      def list_object(columns, object)

        output_format(object)
        object_list = []
        if locate_config_value(:fields)
          locate_config_value(:fields).split(',').each { |n| object_list << ui.color(("#{n}").strip, :bold) }
        else
          columns.each do |column|
            n = (column.split(':').first).strip
            object_list << (ui.color("#{n}", :bold) || 'N/A')
          end
        end

        n_columns = object_list.count
        object_list = [] if locate_config_value(:noheader)

        object.each do |r|
          if locate_config_value(:fields)
            locate_config_value(:fields).downcase.split(',').each { |n| object_list << ((r[("#{n}").strip]).to_s || 'N/A') }
          else
            columns.each { |column| object_list << (r["#{column.split(':').last.strip}"].to_s || 'N/A') }
          end
        end
        puts ui.list(object_list, :uneven_columns_across, n_columns)
        list_object_fields(object) if locate_config_value(:fieldlist)
      end

    end
  end
end
