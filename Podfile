platform :osx, '13.0'


project 'Yippy', {
  'Debug' => :debug,
  'Release' => :release,
  'Beta Debug' => :debug,
  'Beta Release' => :release,
  'XCTest' => :debug
}

target 'Yippy' do
    # Comment the next line if you don't want to use dynamic frameworks
    use_frameworks!

    # Pods for Yippy
    pod 'Default'
    pod 'RxSwift', '~> 5'
    pod 'RxCocoa', '~> 5'

    target 'YippyTests' do
        inherit! :search_paths
        # Pods for testing
        pod 'RxBlocking', '~> 5'
        pod 'RxTest', '~> 5'
        pod 'Default'
        pod 'RxSwift', '~> 5'
        pod 'RxCocoa', '~> 5'
    end

    target 'YippyUITests' do
        inherit! :search_paths
        # Pods for testing
        pod 'RxBlocking', '~> 5'
        pod 'RxTest', '~> 5'
        pod 'Default'
        pod 'RxSwift', '~> 5'
        pod 'RxCocoa', '~> 5'
    end
end
