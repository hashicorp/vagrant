module Vagrant
  module Util
    class ValidateNetmask

      MASK_REGEX = /^(((0|128|192|224|240|248|252|254)\.0\.0\.0)|(255\.(0|128|192|224|240|248|252|254)\.0\.0)|(255\.255\.(0|128|192|224|240|248|252|254)\.0)|(255\.255\.255\.(0|128|192|224|240|248|252|254|255)))$/.freeze

      def self.validate(mask)
        if ! MASK_REGEX.match(mask)
          raise Vagrant::Errors::InvalidNetMask, mask: mask
        end
      end
    end
  end
end
