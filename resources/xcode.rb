include Xcode::Helper

resource_name :xcode
default_action %i(setup install)

property :version, String, name_property: true
property :path, String, default: '/Applications/Xcode.app'
property :ios_simulators, Array

action :setup do
  gem_package 'xcode-install' do
    options('--no-document')
  end
end

action :install do
  CREDENTIALS_DATA_BAG = data_bag_item(:credentials, :apple_id)

  DEVELOPER_CREDENTIALS = {
    XCODE_INSTALL_USER:     CREDENTIALS_DATA_BAG['apple_id'],
    XCODE_INSTALL_PASSWORD: CREDENTIALS_DATA_BAG['password'],
  }.freeze

  execute 'update available Xcode versions' do
    command "#{BASE_COMMAND} update"
    environment DEVELOPER_CREDENTIALS
    not_if { xcode_already_installed?(new_resource.version) }
  end

  execute 'install Xcode' do
    command "#{BASE_COMMAND} install '#{new_resource.version}'"
    environment DEVELOPER_CREDENTIALS
    creates new_resource.path
    not_if { xcode_already_installed?(new_resource.version) }
  end

  simulators_to_install = new_resource.ios_simulators

  simulators_to_install.each do |simulator|
    next if highest_eligible_simulator(simulator_list, simulator).nil?
    semantic_version = highest_eligible_simulator(simulator_list, simulator).join(' ')
    next if available_simulator_versions.include?("#{semantic_version} Simulator (installed)")
    system("#{BASE_COMMAND} simulators --install='#{semantic_version}'")
  end

  execute 'accept license' do
    command '/usr/bin/xcodebuild -license accept'
  end
end
