class Replicant
  def initialize( orgDcm )
    @fname = orgDcm
  end

  def main
    if @fname.include?("DICOMDIR")
      puts "#{@fname} is DicomDIR"
      return false
    end

    if File.directory?( @fname )
      puts "#{@fname} is directory"
      return false
    end

    fp_out = open( @fname + ".out", "wb" )

    open( @fname, "rb" ) do |fp|
      if (dicom_prefix = fp.read(128+4)) == nil
        puts "#{@fname} read error"
        return
      end

      if dicom_prefix.size < 128 + 4 || dicom_prefix.unpack("@128a4") != ["DICM"]
        puts "#{@fname} is not Dicom"
        return
      end

      remained_job = 3

      while remained_job > 0
        data = fp.read( 6 )
        saved_data = data
        break if data.size < 6

        header , saved_data = anal_one_chank( fp, data )
        break if header[:tag0] == nil

        body = fp.read( header[:size] )

        if header[0] == 0x0010 && header[1] == 0x0010 # Patient name
          allget -= 1
          puts "Patient name"
          fp_out.write( header[0].pack("S") )
          fp_out.write( header[1].pack("S") )
          body_size_out( body_size+3 , fp_out )

          pname = body.unpack("A*")[0] + "001"
          fp_out.write( [pname].pack("A*") )

        elsif header[0] == 0x0010 && header[1] == 0x0020  # Patient ID
          allget -= 1
          puts "Patient ID"
          
        elsif header[0] == 0x0020 && header[1] == 0x000D  # Study instance UID
          allget -= 1
          puts "Study instance UID"
          
        else
          fp_out.write( header )
          fp_out.write( body )
        end
      end

      fp_out.write( fp.read )

    end
  end

  def anal_one_chank( fp, data )
    header = data.unpack("S2A2")
    saved_data = header
    ret_header = {:tag0 => header[0], :tag1 => header[1], :vr => header[2]}

    if ["OB","OF","OW","UN","UT"].include?( header[2] )
      saved_data += fp.read(2)
      data = fp.read(4)
      saved_data += data
      ret_header[:size] = data.unpack("L")[0]
      
    elsif ["AE","AS","AT","CS","DA","DS","DT","FL","FD","IS","LO","LT","OD","OL","OV","PN","SH","SL","SS","ST","SV","TM","UC","UI","UL","UR","US","UV"].include?( header[2] )
      saved_data += fp.read(2)
      ret_header[:size] = saved_data.unpack("S")[0]
      
    elsif ["SQ"].include?( header[2] )
      saved_data += fp.read(2)
      size = fp.read(4)
      saved_data += size
      if size.unpack("S2") != [0xFFFF,0xFFFF]
        ret_header[:size] = size.unpack("L")[0]
      else
        saved_data += dum_read_SQ( fp )
      end
    else
      -1
    end
    ret_header, saved_data
  end

  def dum_read_SQ( fp )
    saved_data = ""
    begin
      val = fp.read(2)
#      printf "** 0x%04X ", val.unpack("S")[0]
      saved_data += val
      next if val.unpack("S") != [0xFFFE]
      val2 = fp.read(2)
#      printf "0x%04X\n", val2.unpack("S")[0]
      saved_data += val2
    end while val2.unpack("S") != [0xE0DD]
    saved_data + fp.read(4)
  end
  
  def check_file_path
    return false if @fname.include?("DICOMDIR")
  end
end

if $0 == __FILE__
  Replicant.new(ARGV[0]).main
end
