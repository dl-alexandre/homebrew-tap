#!/usr/bin/env ruby
# update-formulas.rb — Auto-discover formulas and update versions/SHA256 from GitHub releases
require 'octokit'
require 'open-uri'
require 'digest'

client = Octokit::Client.new(access_token: ENV['GITHUB_TOKEN'])
updated = []
formula_dir = ENV.fetch('FORMULA_DIR', 'Formula')

Dir.glob("#{formula_dir}/*.rb").sort.each do |formula_file|
  formula = File.basename(formula_file, '.rb')
  formula_content = File.read(formula_file)

  repo = formula_content[/homepage "https:\/\/github\.com\/([^"]+)"/, 1]
  unless repo
    puts "Skipping #{formula}: no GitHub homepage"
    next
  end

  current_version = formula_content[/version "([^"]+)"/, 1]
  unless current_version
    puts "Skipping #{formula}: no version line (source-build formula)"
    next
  end

  begin
    release = client.latest_release(repo)
    new_version = release.tag_name
    # Tags are usually v1.2.3; formulas may store either form. Compare
    # without the prefix so we do not open a daily PR that only adds "v".
    same_version = new_version.sub(/\Av/, '') == current_version.sub(/\Av/, '')

    if same_version
      puts "#{formula} is up to date (#{new_version})"
      next
    end

    puts "Updating #{formula}: #{current_version} -> #{new_version}"

    new_content = formula_content.gsub(/version "[^"]+"/, %(version "#{new_version}"))

    # Replace release tag in download URLs
    old_tag = formula_content[%r{/releases/download/([^/]+)/}, 1]
    if old_tag
      new_content = new_content.gsub(
        %r{/releases/download/#{Regexp.escape(old_tag)}/},
        "/releases/download/#{new_version}/"
      )

      old_ver = old_tag.sub(/^v/, '')
      new_ver = new_version.sub(/^v/, '')
      new_content = new_content.gsub("_#{old_ver}_", "_#{new_ver}_")
    end

    failed_urls = []
    new_content.scan(/url "(https:[^"]+)"/).flatten.uniq.each do |url|
      begin
        puts "  Downloading #{url}..."
        data = URI.open(url, 'Authorization' => "token #{ENV['GITHUB_TOKEN']}").read
        sha256 = Digest::SHA256.hexdigest(data)
        new_content = new_content.gsub(
          /(#{Regexp.escape(url)}"\s+sha256 ")[^"]+/
        ) { "#{Regexp.last_match(1)}#{sha256}" }
        puts "  SHA256: #{sha256}"
      rescue StandardError => e
        puts "  Error: Could not download #{url}: #{e.message}"
        failed_urls << url
      end
    end

    core_platforms = %w[darwin-amd64 darwin-arm64 linux-amd64 Darwin_x86_64 Darwin_arm64 Linux_x86_64]
    core_failures = failed_urls.select { |u| core_platforms.any? { |p| u.include?(p) } }
    if core_failures.any?
      puts "WARNING: Failed to download core platforms for #{formula}"
      puts "Skipping #{formula} - release assets may not be published yet"
      next
    end

    File.write(formula_file, new_content)
    updated << { formula: formula, version: new_version, repo: repo }
  rescue StandardError => e
    puts "Error processing #{repo}: #{e.message}"
  end
end

if updated.any?
  branch_name = "update-formulas-#{Time.now.strftime('%Y%m%d-%H%M%S')}"
  system('git', 'checkout', '-b', branch_name)
  system('git', 'add', "#{formula_dir}/")

  commit_message = updated.map { |u| "#{u[:formula]}: #{u[:version]}" }.join("\n")
  system('git', 'commit', '-m', "Update formulas\n\n#{commit_message}")
  system('git', 'push', 'origin', branch_name)

  pr_body = updated.map do |u|
    "- **#{u[:formula]}**: #{u[:version]} ([#{u[:repo]}](https://github.com/#{u[:repo]}/releases))"
  end.join("\n")

  tap_repo = ENV.fetch('TAP_REPO', 'dl-alexandre/homebrew-tap')
  tap_branch = ENV.fetch('TAP_BRANCH', 'master')
  client.create_pull_request(
    tap_repo,
    tap_branch,
    branch_name,
    'Update formulas',
    "This PR updates the following formulas:\n\n#{pr_body}"
  )

  File.open(ENV['GITHUB_OUTPUT'], 'a') do |f|
    f.puts 'pr_created=true'
    f.puts "branch_name=#{branch_name}"
  end
  puts "Created PR for #{updated.length} formula(s)"
else
  File.open(ENV['GITHUB_OUTPUT'], 'a') { |f| f.puts 'pr_created=false' }
  puts 'All formulas are up to date'
end