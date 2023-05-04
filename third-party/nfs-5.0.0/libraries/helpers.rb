module Nfs
  module Cookbook
    module Helpers
      # Finds the UID for the given user name
      #
      # @param [String] username
      # @return
      def find_uid(username)
        uid = nil
        Etc.passwd do |entry|
          if entry.name == username
            uid = entry.uid
            break
          end
        end
        uid
      end

      # Finds the GID for the given group name
      #
      # @param [String] groupname
      # @return [Integer] the matching GID or nil
      def find_gid(groupname)
        gid = nil
        Etc.group do |entry|
          if entry.name == groupname
            gid = entry.gid
            break
          end
        end
        gid
      end
    end
  end
end
