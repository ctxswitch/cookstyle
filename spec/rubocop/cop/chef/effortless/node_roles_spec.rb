#
# Copyright:: 2019, Chef Software, Inc.
# Author:: Tim Smith (<tsmith@chef.io>)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'spec_helper'

describe RuboCop::Cop::Chef::ChefEffortless::CookbookUsesRoles, :config do
  subject(:cop) { described_class.new(config) }

  it 'registers an offense when node.role? is used' do
    expect_offense(<<~RUBY)
      node.role?('webserver')
      ^^^^^^^^^^^^^^^^^^^^^^^ Cookbook uses roles, which cannot be used in Policyfiles or Effortless Infra
    RUBY
  end

  it 'registers an offense when node.roles is used' do
    expect_offense(<<~RUBY)
      node.roles.include?('webserver')
      ^^^^^^^^^^ Cookbook uses roles, which cannot be used in Policyfiles or Effortless Infra
    RUBY
  end
end
