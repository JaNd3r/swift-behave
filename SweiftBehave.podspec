
Pod::Spec.new do |s|

  s.name         = "SwiftBehave"
  s.version      = "0.0.1"
  s.summary      = "Behaviour-driven testing framework for Swift."

  s.description  = <<-DESC
                   Behaviour-driven testing framework on top of the Xcode UI Tests that 
                   allows to define acceptance tests using a natural language that all 
                   team members understand.
                   DESC

  s.homepage     = "https://github.com/JaNd3r/swift-behave"
  
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Christian Klaproth" => "ck@cm-works.de" }
  s.social_media_url   = "http://twitter.com/JaNd3r"

  s.platform     = :ios, "9.0"
  s.requires_arc = true

  s.source       = { :git => "https://github.com/JaNd3r/swift-behave.git", :tag => "0.0.1" }

  s.source_files  = "*.{h,m,swift}"

end
