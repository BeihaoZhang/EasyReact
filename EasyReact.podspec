Pod::Spec.new do |s|
  s.name             = 'EasyReact'
  s.version          = '1.1.0'
  s.summary          = 'EasyReact is an easy-to-use library for reactive programming.'

  s.description      = <<-DESC
You may be confused about the functor, applicative and monad while using RxSwift or ReactiveCocoa. However, those concepts are so complicated that only a few people are using them in real projects. So why not do reactive programming in a simpler way? EasyReact makes it easy to use reactive programming in your projects.
DESC

  s.homepage         = 'https://github.com/meituan/EasyReact'
  s.license          = { :type => 'Apache License 2.0', :file => 'LICENSE' }
  s.author           = { 'William Zang' => 'chengwei.zang.1985@gmail.com', '姜沂' => 'nero_jy@qq.com', 'Qin Hong' => 'qinhong@face2d.com'}
  s.source           = { :git => 'https://github.com/meituan/EasyReact.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.module_map = 'EasyReact/EasyReact.modulemap'

  s.source_files = 'EasyReact/Classes/**/*'

  s.requires_arc = 'EasyReact/Classes/{Utils,Core,Categories}/**/*.m'

  s.private_header_files = ['EasyReact/Classes/Core/Private/**/*.h', 'EasyReact/Classes/Core/Transforms/**/*.h']

  s.dependency 'ZTuple', '= 1.2.0'
end
