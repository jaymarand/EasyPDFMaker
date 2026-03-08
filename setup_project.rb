require 'xcodeproj'

project_name = 'PhotoToPDFMaker'
project_path = "#{project_name}.xcodeproj"

# Remove existing project if any
FileUtils.rm_rf(project_path) if Dir.exist?(project_path)

project = Xcodeproj::Project.new(project_path)
target = project.new_target(:application, project_name, :ios, '15.0')

group = project.main_group.find_subpath(File.join(project_name), true)
path = File.expand_path(project_name)

# Collect all files
source_files = Dir.glob("#{path}/**/*.swift")
assets_path = "#{path}/Assets.xcassets"
info_plist_path = "#{path}/Info.plist"

source_files.each do |file|
    file_name = File.basename(file)
    ref = group.new_reference(file)
    target.source_build_phase.add_file_reference(ref)
end

if Dir.exist?(assets_path)
    ref = group.new_reference(assets_path)
    target.resources_build_phase.add_file_reference(ref)
end

target.build_configurations.each do |config|
    config.build_settings['INFOPLIST_FILE'] = "#{project_name}/Info.plist"
    config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = "com.example.#{project_name}"
    config.build_settings['SWIFT_VERSION'] = '5.0'
    config.build_settings['TARGETED_DEVICE_FAMILY'] = '1' # iPhone
end

# Base settings on project level as well
project.build_configurations.each do |config|
    config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
    config.build_settings['SWIFT_VERSION'] = '5.0'
end

project.save
puts "Xcode project generated successfully at #{project_path}"
