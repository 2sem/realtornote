# Uncomment the next line to define a global platform for your project
platform :ios, '11.0'

target 'realtornote' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  inhibit_all_warnings!

  # Pods for realtornote
  pod 'XlsxReaderWriter'
  #pod 'DownPicker'
  pod 'DropDown', '2.3.4'
#  pod 'Google-Mobile-Ads-SDK'
#  pod 'Firebase/Core'
  pod 'Firebase/Messaging'
  
  # Add the pod for Firebase Crashlytics
  pod 'Firebase/Crashlytics'

  # Recommended: Add the Firebase pod for Google Analytics
  pod 'Firebase/Analytics'
  
  pod 'Firebase/RemoteConfig'
  
  pod 'KakaoOpenSDK'
  pod 'ProgressWebViewController'
  #pod 'LSExtensions', :path => '~/Projects/leesam/pods/LSExtensions/src/LSExtensions'
  pod 'LSExtensions'
  #pod 'LSCountDownLabel', :path => '~/Projects/leesam/pods/LSCountDownLabel/src/LSCountDownLabel'
  pod 'LSCountDownLabel'
  pod 'GADManager'#, :path => '~/Projects/leesam/pods/GADManager/src/GADManager'
  pod 'Alamofire'
  #pod 'AnimatedGradientView'
  
  pod 'Toast-Swift'
  pod 'SwiftGifOrigin' #https://cocoapods.org/pods/SwiftGifOrigin
  pod 'RxSwift'
  pod 'RxCocoa'
  pod 'RxDataSources'
  
  pod 'StringLogger'#, '0.4'
#, :git => 'https://github.com/2sem/StringLogger'

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
