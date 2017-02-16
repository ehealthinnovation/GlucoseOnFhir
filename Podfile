source 'https://github.com/CocoaPods/Specs'
use_frameworks!

target 'GlucoseOnFhir' do
  pod 'CCGlucose', :git => 'https://github.com/uhnmdi/CCGlucose.git'
  pod 'CCBluetooth', :git => 'https://github.com/uhnmdi/CCBluetooth.git'
  pod 'CCToolbox', :git => 'https://github.com/uhnmdi/CCToolbox.git'
  pod 'SMART', :git => 'https://github.com/uhnmdi/Swift-SMART.git', :submodules => true
    
  target 'GlucoseOnFhirTests' do
    inherit! :search_paths

  end
end
