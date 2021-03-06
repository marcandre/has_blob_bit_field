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
    let(:initial_flags) { [
          false, false, false, true,   false, false, true,  false,
          false, false, true,  true,   false, true,  false, false,
          false, true,  false, true,   false, true,  true,  false,
        ]}
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

      it "should raise when given another value than true/false" do
        subject[23] = true # no problem here
        [0, nil, :false, 'f'].each do |bad_value|
          expect { subject[1] = bad_value }.to raise_error TypeError
        end
      end
    end

    context "when replaced" do
      context "with an array of booleans" do
        before {  instance.test_flags = [false, true, true, true,
                                         false, false, false, false,
                                         false, true] }
        its(:raw_value) { should == "\x70\x40".b }
        its(:record) { should be_changed }
      end

      context "with another accessors" do
        let(:other) { TestModel.new }
        before do
          other.test_flags_blob = "Hello".b
          instance.test_flags = other.test_flags
        end
        its(:raw_value) { should == "Hello".b }
        its(:record) { should be_changed }
      end
    end

    context "when enumerated" do
      its(:each) { should be_a Enumerator }

      it "should yield true/false for each element" do
        subject.each.to_a.should == initial_flags
      end
    end

    context "when calling map!" do
      its(:map!) { should be_a Enumerator }
      before { subject.map!{ |b| !b } }
      its(:raw_value) { should == "\xED\xCB\xA9".b }
    end

    context "when compared" do
      context "with an array of booleans" do
        it { should == initial_flags }
        it { should_not == [] }
        it { should_not == initial_flags.reverse }
      end

      context "with another accessor" do
        let(:other) { TestModel.new }
        it { should_not == other.test_flags }
        it "should not match with different value" do
          other.test_flags_blob = "Hello".b
          subject.should_not == other.test_flags
        end

        it "should match with the same value" do
          other.test_flags_blob = "\x12\x34\x56".b
          subject.should == other.test_flags
        end
      end
    end

  end

end
