require "http/client"
require "yaml"

{% if flag?(:x86_64) || flag?(:i386) || flag?(:aarch64) || flag?(:arm) %}
  puts "Fetching SIMDe sources…"
{% else %}
  abort("Unsupported platform for SIMDe!", 1)
{% end %}

project_dir = Path["#{__DIR__}"].parent

abort("Missing native libraries lockfile!", 1) unless File.exists? "./native.lock.yml"
native_lock = File.open("#{project_dir.join "native.lock.yml"}") do |lockfile|
  YAML.parse(lockfile)
end
abort("Missing \"simde\" key in ./native.lock.yml", 1) if native_lock["simde"]?.nil? || native_lock["simde"].as_s?.nil?
simde_version = native_lock["simde"].as_s
binaries_url = "https://github.com/simd-everywhere/simde/releases/download/v#{simde_version}/simde-amalgamated-#{simde_version}.tar.xz"

tmp_zip = "#{Dir.tempdir}/#{Path[binaries_url].basename}"
unless File.exists? tmp_zip
  puts "Downloading #{binaries_url}…"

  response = HTTP::Client.get binaries_url
  # Follow redirect
  if (response.status_code == 302 && !response.headers["location"].nil?)
    response = HTTP::Client.get response.headers["location"]
  end
  if (response.status_code != 200)
    puts response.status_code
    exit(1)
  end

  File.write(tmp_zip, response.body)
end

simde_amalgamated_path = Path["#{__DIR__}", "/simde-amalgamated"]
unless File.exists? simde_amalgamated_path
  puts "Deflating SIMDe sources…"
  Process.run("tar", ["-xzf", "#{tmp_zip}"], chdir: "#{__DIR__}")
  File.rename Path["#{simde_amalgamated_path}-#{simde_version}"], simde_amalgamated_path
end

puts "Done"
