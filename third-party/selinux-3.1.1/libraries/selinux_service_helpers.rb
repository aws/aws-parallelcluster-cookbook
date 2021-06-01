module SELinuxServiceHelpers
  # Take various boolean-like values and return 'on' or 'off'
  #
  # @param bool [String, Boolean] Boolean-like value
  # @return [String] on or off
  def self.selinux_bool(bool)
    if ['on', 'true', '1', true, 1].include? bool
      'on'
    elsif ['off', 'false', '0', false, 0].include? bool
      'off'
    else
      Chef::Log.warn "Not a valid boolean value: #{bool}"
      nil
    end
  end
end
