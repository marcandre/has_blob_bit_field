require 'spec_helper'

class TestModel
  include ActiveModel::Dirty
  define_attribute_methods [:test_flags_blob]
  attr_accessor :test_flags_blob
  has_blob_bit_field :test_flags
end

describe HasBlobBitField do
  let(:instance) { TestModel.new }
  subject { instance.test_flags }

  it { should be_a HasBlobBitField::Accessor }

  context "when blob is initially nil" do
    its(:length) { should == 0 }

    it "can be resized" do
      subject.length = 0
      subject.length.should == 0
      subject.length = 18
      instance.test_flags_blob.should == "\x00\x00\x00".b
    end

    it "should raise when reading or writing" do
      expect { subject[0] }.to raise_error IndexError
      expect { subject[0] = false }.to raise_error IndexError
    end
  end

  context "when blob has data" do
    before { instance.test_flags_blob = "\x12\x34\x56".b }
    its(:length) { should == 24 }

    context "when resized" do
      context "down" do
        before { subject.length = 4 }
        its(:length) { should == 8 }
        its(:raw_value) { should == "\x12".b }
        its(:record) { should be_changed }
      end

      context "up" do
        before { subject.length = 38 }
        its(:length) { should == 40 }
        its(:raw_value) { should == "\x12\x34\x56\x00\x00".b }
        its(:record) { should be_changed }
      end

      context "to original size" do
        before { subject.length = 24 }
        its(:length) { should == 24 }
        its(:raw_value) { should == "\x12\x34\x56".b }
        its(:record) { should_not be_changed }
      end
    end

    context "when reading" do
      flags = [false, false, false, true, false, false, true, false]
      flags.each_with_index do |flag, i|
        its([i]) { should == flag }
      end

      it "should raise when reading outside of 0...size" do
        subject[23] # no problem here
        expect { subject[-1] }.to raise_error IndexError
        expect { subject[24] }.to raise_error IndexError
      end
    end

    context "when writing" do
      context "setting a flag" do
        before { subject[2*8+0] = true }
        its(:length) { should == 24 }
        its(:raw_value) { should == "\x12\x34\xD6".b }
        its(:record) { should be_changed }
      end

      context "clearing a flag" do
        before { subject[2*8+1] = false }
        its(:length) { should == 24 }
        its(:raw_value) { should == "\x12\x34\x16".b }
        its(:record) { should be_changed }
      end

      it "should raise when reading outside of 0...size" do
        subject[23] = true # no problem here
        expect { subject[-1] = false }.to raise_error IndexError
        expect { subject[24] = false }.to raise_error IndexError
      end
    end

  end

end
