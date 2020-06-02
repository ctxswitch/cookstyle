#
# Copyright:: 2020, Chef Software, Inc.
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

describe RuboCop::Cop::Chef::ChefDeprecations::ResourceUsesOnlyResourceName do
  subject(:cop) { described_class.new }

  before do
    skip 'Test not currently supported on Windows!' if RuboCop::Platform.windows?
  end

  let(:non_match_json) do
    <<~DATA
    {
    	"name": "default",
    	"description": "Installs some stuff",
    	"maintainer": "Bob Boberson",
    	"maintainer_email": "bob@example.com",
    	"license": "Apache-2.0",
    	"platforms": {},
    	"dependencies": {},
    	"recommendations": {},
    	"suggestions": {},
    	"conflicting": {},
    	"providing": {},
    	"replacing": {},
    	"attributes": {},
    	"groupings": {},
    	"recipes": {},
    	"version": "1.0.0"
    }
    DATA
  end

  let(:match_json) do
    non_match_json.gsub('default', 'my_cookbook')
  end

  it 'registers an offense when a resource has resource_name and does not use provides' do
    expect_offense(<<~RUBY, '/mydevdir/cookbooks/my_cookbook/resources/foo.rb')
      resource_name :my_cookbook_foo
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Starting with Chef Infra Client 16, using `resource_name` without also using `provides` will result in resource failures. Use `provides` to change the name of the resource instead and omit `resource_name` entirely if it matches the name Chef Infra Client automatically assigns based on COOKBOOKNAME_FILENAME.
    RUBY
  end

  it 'autocorrect deletes the resource_name if it the default name based on metadata.json data' do
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:read).and_call_original
    allow(File).to receive(:exist?).with('/mydevdir/cookbooks/my_cookbook/metadata.rb').and_return(false)
    allow(File).to receive(:exist?).with('/mydevdir/cookbooks/my_cookbook/metadata.json').and_return(true)
    allow(File).to receive(:read).with('/mydevdir/cookbooks/my_cookbook/metadata.json').and_return(match_json)
    corrected = autocorrect_source(<<~RUBY, '/mydevdir/cookbooks/my_cookbook/resources/foo.rb')
      resource_name :my_cookbook_foo
    RUBY

    expect(corrected).to eq("\n")
  end

  it 'autocorrect renames resource_name to provides if it is not the default name based on metadata.json data' do
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:read).and_call_original
    allow(File).to receive(:exist?).with('/mydevdir/cookbooks/my_cookbook/metadata.rb').and_return(false)
    allow(File).to receive(:exist?).with('/mydevdir/cookbooks/my_cookbook/metadata.json').and_return(true)
    allow(File).to receive(:read).with('/mydevdir/cookbooks/my_cookbook/metadata.json').and_return(non_match_json)
    corrected = autocorrect_source(<<~RUBY, '/mydevdir/cookbooks/my_cookbook/resources/foo.rb')
      resource_name :my_cookbook_foo
    RUBY

    expect(corrected).to eq("provides :my_cookbook_foo\n")
  end

  it "doesn't register an offense when a resource has just provides" do
    expect_no_offenses(<<~RUBY, '/mydevdir/cookbooks/my_cookbook/resources/foo.rb')
      provides :my_cookbook_foo
    RUBY
  end

  it "doesn't register an offense when a resource has resource_name and provides" do
    expect_no_offenses(<<~RUBY, '/mydevdir/cookbooks/my_cookbook/resources/foo.rb')
      resource_name :my_cookbook_foo
      provides :my_cookbook_foo
    RUBY
  end
end
