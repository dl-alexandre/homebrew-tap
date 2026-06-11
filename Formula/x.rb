class X < Formula
  desc "Terminal-first CLI for X/Twitter with native Go transaction ID generation"
  homepage "https://github.com/dl-alexandre/X-CLI"
  url "https://github.com/dl-alexandre/X-CLI/archive/refs/tags/v0.0.1.tar.gz"
  sha256 "ce77e77e303d73fb0ce151c939879c2c74bed6794f81e969639682da84517ac8"
  license "MIT"

  depends_on "go" => :build

  def install
    system "go", "build", "-ldflags", "-s -w", "-o", bin/"x", "./cmd/x"
    pkgshare.install "config.example.yaml"
  end

  def caveats
    <<~EOS
      X-CLI installed successfully!
      
      To get started:
        mkdir -p ~/.config/x
        cp #{pkgshare}/config.example.yaml ~/.config/x/config.yaml
        x doctor
        
      For native transport (10x faster writes):
        https://github.com/dl-alexandre/X-CLI/blob/master/NATIVE_VERIFICATION.md
    EOS
  end

  test do
    assert_match "x", shell_output("#{bin}/x version")
  end
end
