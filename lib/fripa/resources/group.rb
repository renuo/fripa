# frozen_string_literal: true

module Fripa
  module Resources
    class Group < Base
      def find(cn = nil, **options)
        args = cn ? [cn] : []
        call("group_find", args, options)
      end

      def show(cn)
        validate_identifier!(cn, "cn")
        call("group_show", [cn])
      end

      def add(cn, **attributes)
        validate_identifier!(cn, "cn")
        call("group_add", [cn], attributes)
      end

      def mod(cn, **attributes)
        validate_identifier!(cn, "cn")
        validate_attributes!(attributes)
        call("group_mod", [cn], attributes)
      end

      def delete(cn)
        validate_identifier!(cn, "cn")
        call("group_del", [cn])
      end

      def add_member(cn, **members)
        validate_identifier!(cn, "cn")
        validate_attributes!(members)
        call("group_add_member", [cn], members)
      end

      def remove_member(cn, **members)
        validate_identifier!(cn, "cn")
        validate_attributes!(members)
        call("group_remove_member", [cn], members)
      end

      def add_member_manager(cn, **managers)
        validate_identifier!(cn, "cn")
        validate_attributes!(managers)
        call("group_add_member_manager", [cn], managers)
      end

      def remove_member_manager(cn, **managers)
        validate_identifier!(cn, "cn")
        validate_attributes!(managers)
        call("group_remove_member_manager", [cn], managers)
      end
    end
  end
end
