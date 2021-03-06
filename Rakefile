#
# Copyright (c) 2015 Mark Heily <mark@heily.com>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
# 
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#

require 'rake/testtask'

task :default do
  sh 'erb -T 2 man/launchd.plist.5.erb > man/launchd.plist.5'
end

Rake::TestTask.new do |t|
  t.libs << "lib"
  t.test_files = FileList['test/unit/*.rb', 'test/tc_*.rb']
  t.verbose = true
end

task :install do
  # TODO: make these configurable
  pkgconfigdir='/usr/local/etc/launchd'
  pkgdatadir='/usr/local/share/launchd'
  pkglibdir='/usr/local/lib/launchd'
  bindir='/usr/local/bin'
  sbindir='/usr/local/sbin'
  mandir='/usr/local/man'

  sh 'rake' # to build manpages
  
  FileUtils.cp 'bin/launchd.rb', "#{sbindir}/launchd"
  FileUtils.cp 'bin/launchctl.rb', "#{bindir}/launchctl"
  system "rm -rf #{pkglibdir}/../launchd" if Dir.exist? pkglibdir 
  system "cp -R lib #{pkglibdir}"

  [pkgconfigdir, pkgdatadir].each do |dir|
    FileUtils.mkdir_p([dir, "#{dir}/LaunchAgents", "#{dir}/LaunchDaemons"])
  end 

  Dir.glob("man/*.[0-9]").each do |manpage|
    section = manpage.gsub(/.*\./, '')
    system "cat #{manpage} | gzip > #{mandir}/man#{section}/#{File.basename(manpage)}.gz"
  end
 
  case `uname`.chomp
  when 'FreeBSD'
    FileUtils.cp 'rc/rc.FreeBSD', '/usr/local/etc/rc.d/launchd'
    File.chmod 0755, '/usr/local/etc/rc.d/launchd'
  when 'Linux'
    if File.exist? '/etc/debian_version'
      FileUtils.cp 'rc/rc.Linux', '/etc/init.d/launchd'
      File.chmod 0755, '/etc/init.d/launchd'
      system "ln -sf ../init.d/launchd /etc/rc3.d/S99launchd"
    else
      raise 'Unsupported variant of Linux'
    end
  else
    puts 'WARNING: unknown OS, no init script has been installed'
  end
end
