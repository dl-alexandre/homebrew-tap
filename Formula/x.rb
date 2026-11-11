class X < Formula
  desc "Terminal-first CLI for X/Twitter with native Go transaction ID generation"
  homepage "https://github.com/dl-alexandre/X-CLI"
  url "https://github.com/dl-alexandre/X-CLI/archive/refs/tags/v0.0.4.tar.gz"
  sha256 "0375d3d35a90b5bd5b8c4f889d76e192cb6c395e78a1dd055da2c8d2cc93c53d"
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
