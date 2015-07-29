
require 'etc'



  def fix_encoding(str)
    str.force_encoding(Encoding.default_external) if str.respond_to?(:force_encoding)
    str
  end

  def parse_passwd_line(line,mash)
    line.chomp!
    if line.chr == '+' 
      parse_netgroup_line(line,mash)
    else
      entry = parse_pw_line(line)
      mash[:passwd][entry[:name]] = entry.except(:name) unless mash[:passwd].has_key?(entry[:name])
    end 
    mash
  end 

  def parse_netgroup_line(line,mash)
    pw_line = line[1..-1]
    entry = parse_pw_line(line)
    if( entry[:name].nil? )
      if( entry[:shell] )   
        #+:::::/afs/slac.stanford.edu/common/etc/use-NOT
        mash[:netgroup]['all'] = entry[:shell]
      else
        #+
        mash[:netgroup]['all'] = 'allowed'
      end
    else 
      if entry[:name].chr == '@'
        #+@netgroup
        mash[:netgroup][entry[:name][1..-1]] = 'allowed'
      else
        #+user
        nis = Etc.getpwnam(entry[:name])
        set_if_not(entry, :uid, nis.uid)
        set_if_not(entry, :gid, nis.gid)
        set_if_not(entry, :gecos, nis.gecos)
        set_if_not(entry, :dir, nis.dir)
        set_if_not(entry, :shell, nis.shell)
        mash[:passwd][entry[:name]] = entry.except(:name) unless mash[:passwd].has_key?(entry[:name])
      end
    end
  end

  def parse_pw_line(line)
    entry = Hash.new
    parsed_line = line.split(':')
    set_if(entry, :name, clean_string(parsed_line[0]))
    set_if(entry, :uid, clean_int(parsed_line[2]))
    set_if(entry, :gid, clean_int(parsed_line[3]))
    set_if(entry, :gecos, clean_string(parsed_line[4]))
    set_if(entry, :dir, clean_string(parsed_line[5]))
    set_if(entry, :shell, clean_string(parsed_line[6]))
    entry
  end 

  def parse_group_line(line,etc)
    true 
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

  
      etc = Hash.new

      etc[:passwd] = Hash.new
      etc[:group] = Hash.new
      etc[:netgroups] = Hash.new

    
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




