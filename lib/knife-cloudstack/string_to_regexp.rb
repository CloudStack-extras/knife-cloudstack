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

class String
  def to_regexp
    return nil unless self.strip.match(/\A\/(.*)\/(.*)\Z/mx)
    regexp , flags = $1 , $2
    return nil if !regexp || flags =~ /[^xim]/m

    x = /x/.match(flags) && Regexp::EXTENDED
    i = /i/.match(flags) && Regexp::IGNORECASE
    m = /m/.match(flags) && Regexp::MULTILINE

    Regexp.new regexp , [x,i,m].inject(0){|a,f| f ? a+f : a }
  end
end

