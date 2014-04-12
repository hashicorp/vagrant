shared_examples_for 'any VagrantConfigProvisioner strict boolean attribute' do |attr_name, attr_default_value|

  [true, false].each do |bool|
    it "returns the assigned boolean value (#{bool})" do
      subject.send("#{attr_name}=", bool)
      subject.finalize!

      expect(subject.send(attr_name)).to eql(bool)
    end
  end

  it "returns the default value (#{attr_default_value}) if undefined" do
    subject.finalize!

    expect(subject.send(attr_name)).to eql(attr_default_value)
  end

  [nil, 'true', 'false', 1, 0, 'this is not a boolean'].each do |nobool|
    it "returns the default value when assigned value is invalid (#{nobool.class}: #{nobool})" do
      subject.send("#{attr_name}=", nobool)
      subject.finalize!

      expect(subject.send(attr_name)).to eql(attr_default_value)
    end
  end

end

