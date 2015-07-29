
require 'etc'

Ohai.plugin(:PasswdMin) do
  provides 'etc', 'current_user'

  def fix_encoding(str)
    str.force_encoding(Encoding.default_external) if str.respond_to?(:force_encoding)
    str
  end

  def parse_password_line(line,etc) 
    line.chomp!
    if line.chr == '+' 
      parse_netgroup_line(line,etc)
    else
      entry = parse_pw_line(line)
      etc[:passwd][entry[:name] = entry.except(:name) unless etc[:passwd].has_key?(entry[:name])
    end 
  end 

  def parse_netgroup_line(line,etc)
    #+user

    #+@netgroup

    #+:::::/afs/slac.stanford.edu/common/etc/use-NOT

    #+
  end 

  def parse_pw_line(line)
    entry = Mash.new
    parsed_line = line.split(':')
    entry[:name] = fix_encoding(parsed_line[0])
    entry[:uid] = parsed_line[2].to_i
    entry[:gid] = parsed_line[3].to_i
    entry[:gecos] = parsed_line[4]
    entry[:dir] = parsed_line[5]
    entry[:shell] = parsed_line[6]
    entry
  end 

  collect_data do
    unless etc
      etc Mash.new

      etc[:passwd] = Mash.new
      etc[:group] = Mash.new
      etc[:netgroups] = Mash.new

      File.open("/etc/passwd", "r") do |f|
       f.each_line do |line|
          parse_passwd_line(line,etc)
        end
      end

      File.open("/etc/group", "r") do |f|
        f.each_line do |line|
          parse_group_line(line,etc)
        end
      end

      Etc.passwd do |entry|
        user_passwd_entry = Mash.new(:dir => entry.dir, :gid => entry.gid, :uid => entry.uid, :shell => entry.shell, :gecos => entry.gecos)
        user_passwd_entry.each_value {|v| fix_encoding(v)}
        entry_name = fix_encoding(entry.name)
        etc[:passwd][entry_name] = user_passwd_entry unless etc[:passwd].has_key?(entry_name)
      end

      Etc.group do |entry|
        group_entry = Mash.new(:gid => entry.gid,
                               :members => entry.mem.map {|u| fix_encoding(u)})

        etc[:group][fix_encoding(entry.name)] = group_entry
      end
    end

    unless current_user
      current_user fix_encoding(Etc.getpwuid(Process.euid).name)
    end
  end

  collect_data(:windows) do
    # Etc returns nil on Windows
  end

end
