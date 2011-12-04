require "tempfile"

shared_context "unit" do
  # This helper creates a temporary file and returns a Pathname
  # object pointed to it.
  def temporary_file(contents=nil)
    f = Tempfile.new("vagrant-unit")

    if contents
      f.write(contents)
      f.flush
    end

    return Pathname.new(f.path)
  end
end
