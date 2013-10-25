require "spec_helper"

describe Mongoid::Giza::Index do
  let(:index) { Mongoid::Giza::Index.new }

  it "should have a list of fields" do
    expect(index.fields).to be_a_kind_of(Array)
  end
end
