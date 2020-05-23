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
    human = 
    1.upto( @num_replicants ) do |num|
      new_dcm_path = copy_dcm(num)
      dcm = DICOM::DObject.read( new_dcm_path )
      dcm["0010,0010"].value = "DICOMKENSYO_Name" # Patient Name
      dcm["0010,0020"].value = "DICOMKENSYO_"+sprintf("%03d", num) # Patient ID
    end
  end

  def copy_dcm(i)
    if (extname = File.extname(@dcm_fname)) == ""
      new_dcm_path = @dcm_fname + sprintf( "_%03d", i )
    else
      new_dcm_path = File.basename( @dcm_fname, extname ) + sprintf( "_%03d", i ) + extname
    end
    FileUtils.cp @dcm_fname, new_dcm_path
    new_dcm_path
  end

  def confirm
    Dir.glob( "./US000001_*" ).map do |fpath|
      dcm = DICOM::DObject.read(fpath)
      puts "name,ID : #{dcm.value("0010,0010")}, #{dcm.value("0010,0020")}"
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
