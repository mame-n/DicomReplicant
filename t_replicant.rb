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

  def test_confirm_dcm
    num_reps = 2.to_s

    dcm = "DicomFiles/DICOMDIR"
    obr = Replicant.new([dcm, num_reps])
    assert_equal( false, obr.confirm_dcm )

    dcm = "DicomFiles"
    obr = Replicant.new([dcm, num_reps])
    assert_equal( false, obr.confirm_dcm )

    dcm = "DicomFiles/foo"
    obr = Replicant.new([dcm, num_reps])
    assert_equal( false, obr.confirm_dcm )

    dcm = "DicomFiles/TestFile"
    obr = Replicant.new([dcm, num_reps])
    assert_equal( false, obr.confirm_dcm )

    dcm = "DicomFiles/A0000"
    obr = Replicant.new([dcm, num_reps])
    assert_equal( true, obr.confirm_dcm )
  end

  def test_copy_dcm
    dcm_org_path = "DicomFiles/A0000"
    obr = Replicant.new( [dcm_org_path, "3"] )
    assert_equal( dcm_org_path, obr.dcm_fname )
    dcm_mod_path = obr.copy_dcm( 3 )
    puts "**** dcm_mod_path = #{dcm_mod_path}"
    dcm_org = DICOM::DObject.read( dcm_org_path )
    dcm_mod = DICOM::DObject.read( dcm_mod_path )
    assert_equal( true, dcm_org == dcm_mod )
  end
    
  def test_main
    dcm_org_path = "DicomFiles/A0000"
    num_replicants = 3
    obr = Replicant.new( [dcm_org_path, num_replicants.to_s] )
    obr.main
    dcms( num_replicants, dcm_org_path ).each_with_index do |dcm, num|
      assert_equal( "DICOMKENSYO_Name", dcm["0010,0010"].value )
      assert_equal( "DICOMKENSYO_" + sprintf( "_%03d", num ), dcm["0010,0020"].value )
    end
  end

  def dcms( num_replicants, dcm_org_path )
    1.upto( num_replicants ).map do |num|
      DICOM::DObject.read( dcm_org_path + sprintf( "_%03d", num ) )
    end
  end

end
