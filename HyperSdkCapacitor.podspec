require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

hyper_sdk_version = "2.2.2"

begin
  package_json_path = File.expand_path(File.join(__dir__, "../../package.json"))
  puts "Reading package.json from #{package_json_path}"
  apps_package = JSON.parse(File.read(package_json_path))
  if apps_package["hyperSdkIOSVersion"]
    override_version = apps_package["hyperSdkIOSVersion"]
    hyper_sdk_version = Gem::Version.new(override_version) > Gem::Version.new(hyper_sdk_version) ? override_version : hyper_sdk_version
    if hyper_sdk_version != override_version
      puts ("Ignoring the overriden SDK version present in package.json (#{override_version}) as there is a newer version present in the SDK (#{hyper_sdk_version}).").yellow
    end
  end
rescue => e
  puts ("An error occurred while overrding the IOS SDK Version. #{e.message}").red
end

Pod::Spec.new do |s|
  s.name = 'HyperSdkCapacitor'
  s.version = package['version']
  s.summary = package['description']
  s.license = package['license']
  s.homepage = package['repository']['url']
  s.author = package['author']
  s.source = { :git => package['repository']['url'], :tag => s.version.to_s }
  s.source_files = 'ios/Plugin/**/*.{swift,h,m,c,cc,mm,cpp}'
  s.ios.deployment_target  = '13.0'
  s.dependency 'Capacitor'
  s.dependency "HyperSDK", hyper_sdk_version
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
end
