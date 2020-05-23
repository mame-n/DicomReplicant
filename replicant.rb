require 'fileutils'
require 'dicom'

class Replicant
  def initialize( argvs )
    check_argvs( argvs )
  end

  def check_argvs( argvs )
    if argvs.size == 0
      puts_usage
      @dcm_fname = nil
    
    elsif argvs.size == 1
      @num_replicants = 10 # Default
      puts "No number of replicants is specified. Set default as #{@num_replicants}"
      @dcm_fname = argvs[0]
    
    else
      @num_replicants = argvs[1].to_i
      @dcm_fname = argvs[0]
    end
  end

  attr_accessor :dcm_fname, :num_replicants, :dcm_instance

  def confirm_dcm
    return false unless @dcm_fname

    if File.directory?( @dcm_fname )
      puts "#{@dcm_fname} is directory"
      return false
    end

    if @dcm_fname.include?("DICOMDIR")
      puts "#{@dcm_fname} is DicomDIR"
      return false
    end

    @human_dcm = DICOM::DObject.read( @dcm_fname )
    if @human_dcm.read?
      return true
    else
      puts "#{@dcm_fname} seems not to be DICOM"
      return false
    end
  end

  def main
    return false if confirm_dcm

    @human_dcm["0010,0010"].value = "DICOMKENSYO_Name" # Patient Name
    
    1.upto( @num_replicants ) do |num|
      @human_dcm["0010,0020"].value = "DICOMKENSYO_"+sprintf("%03d", num) # Patient ID
      @human_dcm.write( replicant_name( num ) )
    end

  end

  def replicant_name(i)
    if (extname = File.extname(@dcm_fname)) == ""
      @dcm_fname + sprintf( "_%03d", i )
    else
      File.basename( @dcm_fname, extname ) + sprintf( "_%03d", i ) + extname
    end
  end

  def puts_usage
    puts "No input file path is specified."
    puts "useg: relicant <original file path> <number of duplicating files>"
  end

end

if $0 == __FILE__
  Replicant.new(ARGV).main
end
