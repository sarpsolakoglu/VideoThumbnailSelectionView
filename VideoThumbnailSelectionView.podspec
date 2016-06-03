Pod::Spec.new do |s|

  s.name         = "VideoThumbnailSelectionView"
  s.version      = "0.1.0"
  s.summary      = "Easy drag and drop library for Instagram like video thumbnail selection."

  s.description  = <<-DESC
                    This library is a drag and drop component for easy video thumbnail selection that is
                    similar to Instagram's video cover selection. I am currently using this component
                    actively in a project.
                   DESC

  s.homepage     = "https://github.com/sarpsolakoglu/VideoThumbnailSelectionView"

  s.license      = "MIT"

  s.author             = { "Sarp Ogulcan Solakoglu" => "sosolakoglu@gmail.com" }
  s.social_media_url   = "http://twitter.com/sarpsolakoglu"

  s.platform     = :ios, "8.0"

  s.source       = { :git => "https://github.com/sarpsolakoglu/VideoThumbnailSelectionView.git", :tag => "0.1.0" }

  s.source_files  = "VideoThumbnailSelectionView/*.{swift}"
  s.resources = "VideoThumbnailSelectionView/*.{xib}"

  s.frameworks = "UIKit", "AVFoundation"

end
