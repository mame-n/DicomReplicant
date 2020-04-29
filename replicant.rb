class Replicant
  def initialize( orgDcm )
    @fname = orgDcm
  end

  def main
    unless check_file_path
      puts "#{@fname} is not Dicom"
      return
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
        break if data.size < 6

        header = data.unpack("S2A2")
        body_size = body_size( fp, header )
        break if body_size == -1

        body = fp.read( body_size )

        if header[0] == 0x0010 && header[1] == 0x0010 # Patient name
          allget -= 1
          fp_out.write( header[0].pack("S") )
          fp_out.write( header[1].pack("S") )
          body_size_out( body_size+3 , fp_out )

          pname = body.unpack("A*")[0] + "001"
          fp_out.write( [pname].pack("A*") )

        elsif header[0] == 0x0010 && header[1] == 0x0020  # Patirnt ID
          allget -= 1
          
        elsif header[0] == 0x0020 && header[1] == 0x000D  # Study instance UID
          allget -= 1
          
        else
          fp_out.write( header )
          fp_out.write( body )
        end
      end

      fp_out.write( fp.read )

    end
  end
end

if $0 == __FILE__
  Identy.new(ARGV[0]).main
end
