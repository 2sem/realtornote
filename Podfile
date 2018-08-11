# Uncomment the next line to define a global platform for your project
platform :ios, '10.0'

target 'realtornote' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  inhibit_all_warnings!

  # Pods for realtornote
  pod 'XlsxReaderWriter'
  pod 'DownPicker'
  pod 'Google-Mobile-Ads-SDK'
  pod 'Firebase/Core'
  pod 'Firebase/Messaging'
  pod 'Firebase/Crash'
  pod 'KakaoOpenSDK'
  pod 'ProgressWebViewController'
  pod 'LSExtensions', :path => '~/Projects/leesam/pods/LSExtensions/src/LSExtensions'
  pod 'Alamofire'

  target 'realtornoteTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'realtornoteUITests' do
    inherit! :search_paths
    # Pods for testing
  end

#script to do after install pod projects
  post_install do |installer|
      #find target name of "XlsxReaderWriter" from targets in Pods
      XlsxReaderWriter = installer.pods_project.targets.find{ |t| t.name == "XlsxReaderWriter" }
      #puts "capture #{XlsxReaderWriter}";
      #find target name of "XMLDictionary" from targets in Pods
      XMLDictionary = installer.pods_project.targets.find{ |t| t.name == "XMLDictionary" }
      #puts "capture #{XMLDictionary}";
      #find file reference for "XMLDictionary.h" of a Project "XMLDictionary"
      XMLDictionaryHeader = XMLDictionary.headers_build_phase.files
          .find{ |b| b.file_ref.name == "XMLDictionary.h" }.file_ref

      #add reference for "XMLDictionary.h" into project "XlsxReaderWriter"
      XMLDictionaryHeaderBuild = XlsxReaderWriter.headers_build_phase
          .add_file_reference(XMLDictionaryHeader, avoid_duplicates = true);
      #make new file appended public
      XMLDictionaryHeaderBuild.settings = { "ATTRIBUTES" => ["Public"] }
      puts "add #{XMLDictionaryHeader} into XlsxReaderWriter";
      
=begin
       installer.pods_project.targets.each do |target|
        case target.name
       when "XlsxReaderWriter"
       XlsxReaderWriter = target
       puts "capture #{XlsxReaderWriter}";
       when "XMLDictionary"
       target.headers_build_phase.files.each do |build_phase|
       #for i in 0..target.headers_build_phase.files.length - 1
       #file = target.headers_build_phase.files[i];
       file = build_phase.file_ref;
       if file.name == "XMLDictionary.h"
       XMLDictionaryHeader = file;
       puts "capture #{file.inspect}";
       end
       end
       end
       end
=end

  end
end
