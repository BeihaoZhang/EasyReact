Pod::Spec.new do |s|
  s.name             = 'EasyReact'
  s.version          = '2.2.0'
  s.summary          = 'Make reactive programming easier for you.'

  s.description      = <<-DESC
Are you confused by the functors, applicatives, and monads in RxSwift and ReactiveCocoa? It doesn't matter, the concepts are so complicated that not many developers actually use them in normal projects. Is there an easy-to-use way to use reactive programming? EasyReact is born for this reason.
DESC

  s.homepage         = 'https://github.com/meituan/EasyReact'
  s.license          = { :type => 'Apache License 2.0', :file => 'LICENSE' }
  s.author           = { 'William Zang' => 'chengwei.zang.1985@gmail.com', '姜沂' => 'nero_jy@qq.com', 'Qin Hong' => 'qinhong@face2d.com'}
  s.source           = { :git => 'https://github.com/meituan/EasyReact.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.module_map = 'EasyReact/EasyReact.modulemap'

  s.source_files = 'EasyReact/Classes/**/*'

  s.requires_arc = 'EasyReact/Classes/{Utils,Core,Categories}/**/*.m'

  s.requires_arc = true

  s.private_header_files = ['EasyReact/Classes/Core/Private/**/*.h', 'EasyReact/Classes/Core/ListenEdges/**/*.h']

  s.dependency 'EasyFoundation', '~> 1.0.0-alpha'

end
