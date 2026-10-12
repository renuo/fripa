# frozen_string_literal: true

module Fripa
  module Resources
    class User < Base
      REQUIRED_ADD_FIELDS = %i[givenname sn cn].freeze

      def find(uid = nil, **options)
        args = uid ? [uid] : []
        call("user_find", args, options)
      end

      def show(uid)
        validate_identifier!(uid, "uid")
        call("user_show", [uid])
      end

      def add(uid, **attributes)
        validate_identifier!(uid, "uid")
        validate_required_fields!(attributes, REQUIRED_ADD_FIELDS)
        call("user_add", [uid], attributes)
      end

      def mod(uid, **attributes)
        validate_identifier!(uid, "uid")
        validate_attributes!(attributes)
        call("user_mod", [uid], attributes)
      end

      def delete(uid)
        validate_identifier!(uid, "uid")
        call("user_del", [uid])
      end

      # current_password is only needed when users change their own password.
      # Admins can omit it to reset the password of another user.
      def passwd(uid, new_password, current_password = nil, **options)
        validate_identifier!(uid, "uid")
        validate_password!(new_password, "new_password")
        validate_password!(current_password, "current_password") unless current_password.nil?
        call("passwd", [uid, new_password, current_password].compact, options)
      end

      private

      def validate_password!(password, name)
        raise ArgumentError, "#{name} cannot be blank" if password.to_s.strip.empty?
      end
    end
  end
end
