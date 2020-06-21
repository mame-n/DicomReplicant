#require 'fileutils'
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
    puts "Check dcm"
    return false unless confirm_dcm

    puts "Sucsess to confirm dcm"
    @human_dcm["0010,0010"].value = "DICOMKENSYO_Name" # Patient Name
    
    1.upto( @num_replicants ) do |num|
      @human_dcm["0010,0020"].value = "DICOMKENSYO_"+sprintf("%03d", num) # Patient ID
      @human_dcm.write( replicant_name( num ) )
    end

    replicant_confirmation
  end

  def replicant_name(i)
    if (extname = File.extname(@dcm_fname)) == ""
      sprintf( "%s_%03d", @dcm_fname, i )
    else
      # sprintf( "%s_%03d%s", File.basename( @dcm_fname, extname ), i, extname )
      @dcm_fname.gsub( /#{extname}$/ , sprintf( "_%03d%s", i, extname) )
    end
  end

  def replicant_instanceUID( uid, n )
    if uid.size > 57
      uid[57,uid.size-57] = ''  # Max 62 chars.
    end
    uid + ".%04d" % n
  end

  def puts_usage
    puts "No input file path is specified."
    puts "useg: relicant <original file path> <number of duplicating files>"
  end

  def replicant_confirmation
    puts "Expected differenciation is false : [File Meta Information Group Length] and [Source Application Entity Title]"

    dcm_original = DICOM::DObject.read( @dcm_fname )
    dcm_original_hash = dcm_original.to_hash
    1.upto( @num_replicants ) do |num|
      dcm_replicant = DICOM::DObject.read( replicant_name( num ) )
      dcm_replicant_hash = dcm_replicant.to_hash
      dcm_replicant_hash.each do |key, value|
        puts "False #{num}: [#{key} , #{value}] <== #{dcm_original_hash[key]}" unless value == dcm_original_hash[key]
      end
    end
  end
end

if $0 == __FILE__
  Replicant.new(ARGV).main
end
