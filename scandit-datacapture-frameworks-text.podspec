Pod::Spec.new do |s|
    s.name                    = 'scandit-datacapture-frameworks-text'
    s.version                 = '6.22.0'
    s.summary                 = 'Scandit Frameworks Shared Text module'
    s.homepage                = 'https://github.com/Scandit/scandit-datacapture-frameworks-text'
    s.license                 = { :type => 'Apache-2.0' , :text => 'Licensed under the Apache License, Version 2.0 (the "License");' }
    s.author                  = { 'Scandit' => 'support@scandit.com' }
    s.platforms               = { :ios => '13.0' }
    s.source                  = { :git => 'https://github.com/Scandit/scandit-datacapture-frameworks-text.git', :tag => '6.22.0' }
    s.swift_version           = '5.7'
    s.source_files            = 'Sources/**/*.{h,m,swift}'
    s.requires_arc            = true
    s.module_name             = 'ScanditFrameworksText'
    s.header_dir              = 'ScanditFrameworksText'

    s.user_target_xcconfig = { "GENERATE_INFOPLIST_FILE" => "YES" }

    s.dependency 'ScanditTextCapture', '= 6.22.0'
    s.dependency 'scandit-datacapture-frameworks-core', '= 6.22.0'
end
