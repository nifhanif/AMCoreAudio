Pod::Spec.new do |s|
  s.name         = 'AMCoreAudio'
  s.version      = '3.5'
  s.summary      = 'A Swift framework that aims to make Core Audio use less tedious in macOS'

  s.description  = <<-DESC
                   AMCoreAudio is a Swift framework that aims to make Core Audio use less tedious in macOS.

                   Here's a few things it can do:

                   * Simplifying audio device enumeration
                   * Providing accessors for the most relevant audio device properties (i.e., device name, device manufacturer, device UID, volume, mute, sample rate, clock source, etc.)
                   * Managing (physical and virtual) audio streams associated to an audio device
                   * Subscribing to audio hardware, audio device, and audio stream events
                   * etc.
                   DESC

  s.homepage     = 'https://github.com/bitgapp/AMCoreAudio'
  s.license      = { :type => 'MIT', :file => 'LICENSE.md' }
  s.author       = { 'Ruben Nine' => 'ruben@9labs.io' }
  s.social_media_url = 'https://twitter.com/sonicbee9'

  s.platform     = :osx, '10.10'
  s.osx.deployment_target = '10.10'

  s.source       = { :git => 'https://github.com/bitgapp/AMCoreAudio.git', :tag => s.version }
  s.source_files = 'Source/**/*.{swift,h,m}'

  s.requires_arc = true

  s.swift_versions = ['4.0', '4.2', '5.0', '5.1', '5.2']
end
