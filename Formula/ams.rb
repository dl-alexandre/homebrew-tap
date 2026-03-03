class Ams < Formula
  desc "Apple Maps Server API CLI for location services"
  homepage "https://github.com/dl-alexandre/Apple-Map-Server-CLI"
  url "https://github.com/dl-alexandre/Apple-Map-Server-CLI/archive/refs/tags/v0.0.7.tar.gz"
  sha256 "UPDATE_AFTER_PUSH"
  version "v0.0.2"
  license "MIT"

  depends_on "go" => :build

  def install
    cd "cmd/ams" do
      system "go", "build", "-o", bin/"ams", "."
    end
  end

  test do
    system "#{bin}/ams", "version"
  end
end
