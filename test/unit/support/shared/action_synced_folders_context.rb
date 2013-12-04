shared_context "synced folder actions" do
  # This creates a synced folder implementation.
  def impl(usable, name)
    Class.new(Vagrant.plugin("2", :synced_folder)) do
      define_method(:name) do
        name
      end

      define_method(:usable?) do |machine|
        usable
      end
    end
  end
end
