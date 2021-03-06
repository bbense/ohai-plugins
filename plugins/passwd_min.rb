require 'etc'

# A plugin only reads the local password/group files, but 
# is netgroup aware and makes appropriate entries when it
# finds + entries in the files. 

Ohai.plugin(:PasswdMin) do
  provides 'etc', 'current_user'

  def fix_encoding(str)
    str.force_encoding(Encoding.default_external) if str.respond_to?(:force_encoding)
    str
  end

  def parse_passwd_line(line)
    line.chomp!
    if line.chr == '+' 
      parse_netgroup_line(line)
    else
      entry = parse_pw_line(line)
      name = entry[:name]
      entry.delete(:name)
      etc[:passwd][name] = entry
    end
  end 

  def parse_netgroup_line(line)
    pw_line = line[1..-1]
    entry = parse_pw_line(pw_line)
    if( entry[:name].nil? )
      if( entry[:shell] )   
        #+:::::/afs/slac.stanford.edu/common/etc/use-NOT
        etc[:netgroups][:all] = entry[:shell]
      else
        #+
        etc[:netgroups][:all] = 'allowed'
      end
    else 
      if entry[:name].chr == '@'
        #+@netgroup
        etc[:netgroups][entry[:name][1..-1]] = 'allowed'
      else
        #+user
        nis = Etc.getpwnam(entry[:name])
        set_if_not(entry, :uid, nis.uid)
        set_if_not(entry, :gid, nis.gid)
        set_if_not(entry, :gecos, nis.gecos)
        set_if_not(entry, :dir, nis.dir)
        set_if_not(entry, :shell, nis.shell)
        name = entry[:name]
        entry.delete(:name)
        etc[:passwd][name] = entry
      end
    end
  end

  def parse_pw_line(line)
    entry = Mash.new
    parsed_line = line.split(':')
    set_if(entry, :name, clean_string(parsed_line[0]))
    set_if(entry, :uid, clean_int(parsed_line[2]))
    set_if(entry, :gid, clean_int(parsed_line[3]))
    set_if(entry, :gecos, clean_string(parsed_line[4]))
    set_if(entry, :dir, clean_string(parsed_line[5]))
    set_if(entry, :shell, clean_string(parsed_line[6]))
    entry
  end 

  def parse_group_line(line)
    line.chomp!
    if line.chr == '#'
      return 
    end
    if line.chr == '+'
      etc[:group][:uses_nis] = 'true'
      return
    end 
    entry = Mash.new
    parsed_line = line.split(':')
    name = fix_encoding(parsed_line[0])
    entry[:gid] = parsed_line[2].to_i
    entry[:members] = parsed_line[3].to_s.split(",").map { |u| fix_encoding(u) }
    etc[:group][name] = entry
  end 

  def set_if(hash,atom,value)
    if value.respond_to?(:length)
      if value.length > 0 
        hash[atom] = value
      end 
    else
      if value >= 0 
        hash[atom] = value
      end 
    end  
  end
  
  def set_if_not(hash,atom,value)
    if hash[atom].nil? 
      hash[atom] = value
    end 
  end

  def clean_int(string)
    if string.nil? 
      ""
    else 
      if string.length > 0 
        string.to_i 
      else
        "" 
      end
    end 
  end

  def clean_string(string)
    if string.nil? 
      ""
    else 
      if string.length > 0 
        fix_encoding(string) 
      else
        "" 
      end
    end 
  end

  collect_data do

    unless etc
      etc Mash.new

      etc[:passwd] = Mash.new
      etc[:group] = Mash.new
      etc[:netgroups] = Mash.new

      File.open("/etc/passwd", "r") do |f|
         f.each_line do |line|
          parse_passwd_line(line)
         end
      end

      File.open("/etc/group", "r") do |f|
         f.each_line do |line|
           parse_group_line(line)
         end
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
