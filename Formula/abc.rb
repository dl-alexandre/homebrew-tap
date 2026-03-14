class Abc < Formula
  desc "CLI for Apple Business Connect API - manage business presence on Apple Maps"
  homepage "https://github.com/dl-alexandre/Apple-Business-Connect-CLI"
  version "v0.0.4"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/dl-alexandre/Apple-Business-Connect-CLI/releases/download/v0.0.1/abc-darwin-arm64.tar.gz"
      sha256 "3b0a7c540f53915d1a96530e96b5115f7197dcc4b80851cffa8df5473233f9d2"
    end
    if Hardware::CPU.intel?
      url "https://github.com/dl-alexandre/Apple-Business-Connect-CLI/releases/download/v0.0.1/abc-darwin-amd64.tar.gz"
      sha256 "2e0ada41c648be41a2f26f76feeb7967e3fe939c594642b0fdbd8bdf981e4b57"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/dl-alexandre/Apple-Business-Connect-CLI/releases/download/v0.0.1/abc-linux-arm64.tar.gz"
      sha256 "620c074f57fa64ce888af019100b55a27567789bb6e390e90eaf212998cd1ce7"
    end
    if Hardware::CPU.intel?
      url "https://github.com/dl-alexandre/Apple-Business-Connect-CLI/releases/download/v0.0.1/abc-linux-amd64.tar.gz"
      sha256 "58040b0d69377e698df3d65fd76d800938b1831f575ce2d385f3e37d90db3406"
    end
  end

  def install
    bin.install "abc"
  end

  test do
    system "#{bin}/abc", "version"
  end
end
