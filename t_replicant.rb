require "dicom"
require "fileutils"
require "test/unit"
require "./replicant.rb"

class TC < Test::Unit::TestCase
  def setup
  end

  def test_initialize
    dcm = "DCMNAME"
    num_reps = 5
    Replicant.new([])
    obr = Replicant.new([dcm])
    assert_equal( dcm, obr.dcm_fname )
    obr = Replicant.new([dcm,num_reps])
    assert_equal( dcm, obr.dcm_fname )
    assert_equal( num_reps, obr.num_replicants )
  end

  def test_replicant_instanceUID
    obr = Replicant.new(["DicomFiles/A0000"])
    assert_equal( "123.0000", obr.replicant_instanceUID( "123", 0 ))
    assert_equal( "123.0001", obr.replicant_instanceUID( "123", 1 ))
    assert_equal( "123.1234", obr.replicant_instanceUID( "123", 1234 ))
  end

  def test_confirm_dcm
    num_reps = 2.to_s

    # DICOMDIR
    dcm = "DicomFiles/DICOMDIR"
    obr = Replicant.new([dcm, num_reps])
    assert_equal( false, obr.confirm_dcm )

    # Folder / Directory
    dcm = "DicomFiles"
    obr = Replicant.new([dcm, num_reps])
    assert_equal( false, obr.confirm_dcm )

    # Not existed
    dcm = "DicomFiles/foo"
    obr = Replicant.new([dcm, num_reps])
    assert_equal( false, obr.confirm_dcm )

    # Not DICOM fire
    dcm = "DicomFiles/TestFile"
    obr = Replicant.new([dcm, num_reps])
    assert_equal( false, obr.confirm_dcm )

    # DICOM file
    dcm = "DicomFiles/A0000"
    obr = Replicant.new([dcm, num_reps])
    assert_equal( true, obr.confirm_dcm )
  end

  def test_replicant_name
    dcm_org_path = "DicomFiles/A0000"
    obr = Replicant.new( [dcm_org_path, "3"] )
    assert_equal( dcm_org_path, obr.dcm_fname )
    assert_equal( "DicomFiles/A0000_003", obr.replicant_name( 3 ) )
    assert_equal( "DicomFiles/A0000_010", obr.replicant_name( 10 ) )
    assert_equal( "DicomFiles/A0000_123", obr.replicant_name( 123 ) )
    assert_equal( "DicomFiles/A0000_99999", obr.replicant_name( 99999 ) )
    dcm_org_path = "DicomFiles/A0000.dcm"
    obr = Replicant.new( [dcm_org_path, "3"] )
    assert_equal( dcm_org_path, obr.dcm_fname )
    assert_equal( "DicomFiles/A0000_003.dcm", obr.replicant_name( 3 ) )
    assert_equal( "DicomFiles/A0000_010.dcm", obr.replicant_name( 10 ) )
    assert_equal( "DicomFiles/A0000_123.dcm", obr.replicant_name( 123 ) )
    assert_equal( "DicomFiles/A0000_99999.dcm", obr.replicant_name( 99999 ) )
    dcm_org_path = "A0000.dcm"
    obr = Replicant.new( [dcm_org_path, "3"] )
    assert_equal( dcm_org_path, obr.dcm_fname )
    assert_equal( "A0000_003.dcm", obr.replicant_name( 3 ) )
    assert_equal( "A0000_010.dcm", obr.replicant_name( 10 ) )
    assert_equal( "A0000_123.dcm", obr.replicant_name( 123 ) )
    assert_equal( "A0000_99999.dcm", obr.replicant_name( 99999 ) )
    dcm_org_path = "DicomFiles/A00.dcm.00.dcm"
    obr = Replicant.new( [dcm_org_path, "3"] )
    assert_equal( dcm_org_path, obr.dcm_fname )
    assert_equal( "DicomFiles/A00.dcm.00_003.dcm", obr.replicant_name( 3 ) )
    assert_equal( "DicomFiles/A00.dcm.00_010.dcm", obr.replicant_name( 10 ) )
    assert_equal( "DicomFiles/A00.dcm.00_123.dcm", obr.replicant_name( 123 ) )
    assert_equal( "DicomFiles/A00.dcm.00_99999.dcm", obr.replicant_name( 99999 ) )
    dcm_org_path = "DicomFiles/A00.dcm00.dcm"
    obr = Replicant.new( [dcm_org_path, "3"] )
    assert_equal( dcm_org_path, obr.dcm_fname )
    assert_equal( "DicomFiles/A00.dcm00_003.dcm", obr.replicant_name( 3 ) )
    assert_equal( "DicomFiles/A00.dcm00_010.dcm", obr.replicant_name( 10 ) )
    assert_equal( "DicomFiles/A00.dcm00_123.dcm", obr.replicant_name( 123 ) )
    assert_equal( "DicomFiles/A00.dcm00_99999.dcm", obr.replicant_name( 99999 ) )
  end
    
  def test_main
    dcm_org_path = "DicomFiles/A0000"
    num_replicants = 3
    obr = Replicant.new( [dcm_org_path, num_replicants.to_s] )
    obr.main
    1.upto( num_replicants ) do |num|
      puts "Fname +++++ #{obr.replicant_name( num )}"
      dcm = DICOM::DObject.read( obr.replicant_name( num ) )
      assert_equal( "DICOMKENSYO_Name", dcm["0010,0010"].value )
      assert_equal( sprintf( "DICOMKENSYO_%03d", num ), dcm["0010,0020"].value )
      assert_equal( "1.2.392.200036.9116.6.26.10500001.4673.20171208053528075..%04d" % num, dcm["0008,0018"].value )
      File.delete( obr.replicant_name( num ) )
    end
  end

  def dcm_fnames( num_replicants, dcm_org_path )
    1.upto( num_replicants ).map do |num|
      sprintf( "%s_%03d", dcm_org_path, num )
    end
  end
    
  def dcms( num_replicants, dcm_org_path )
    1.upto( num_replicants ).map do |num|
      DICOM::DObject.read( dcm_org_path + sprintf( "_%03d", num ) )
    end
  end
end
