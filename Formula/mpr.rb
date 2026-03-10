class Mpr < Formula
  desc "USDA Market News CLI for agricultural commodity data"
  homepage "https://github.com/dl-alexandre/MyMarketNews-CLI"
  version "v0.0.2"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/dl-alexandre/MyMarketNews-CLI/releases/download/v0.0.1/mpr-darwin-arm64.tar.gz"
      sha256 "59beba9d03c540590f668fe0badbf2e30e542256a1618fa4a4b8f0866b4e6501"
    end
    if Hardware::CPU.intel?
      url "https://github.com/dl-alexandre/MyMarketNews-CLI/releases/download/v0.0.1/mpr-darwin-amd64.tar.gz"
      sha256 "62d2db8fd3e6a953defdb05d9ad8c535674629d10fcd6a1de218077788212635"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/dl-alexandre/MyMarketNews-CLI/releases/download/v0.0.1/mpr-linux-arm64.tar.gz"
      sha256 "13dae260a2b13dbe75087d65a5292a2f551db56283c2cc157ffc5f37190ed33a"
    end
    if Hardware::CPU.intel?
      url "https://github.com/dl-alexandre/MyMarketNews-CLI/releases/download/v0.0.1/mpr-linux-amd64.tar.gz"
      sha256 "4f58e116ab20b8e690eff562616813a2500086070b52bcd08bc9eb17068ac91c"
    end
  end

  def install
    bin.install "mpr"
  end

  test do
    system "#{bin}/mpr", "--version"
  end
end
