# Create a file where the contents is the data we set with
# the Vagrantfile.
file "/tmp/chef_solo_basic" do
  mode    0644
  content node[:test][:data]
end
