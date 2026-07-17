class RetryHelpers < Inspec.resource(1)
  name 'retry_helpers'

  desc '
    Helper methods for retry logic in InSpec tests
  '
  example '
    # Use inside a before block to wait for a condition
    describe yum.repo("aws-fsx") do
      before { retry_helpers.wait_until { command("yum repolist").exit_status == 0 } }
      it { should exist }
    end

    # Wait for a specific command to succeed
    describe yum.repo("aws-fsx") do
      before { retry_helpers.wait_for_command("yum -v repolist all | grep aws-fsx") }
      it { should exist }
    end
  '

  # Waits until a condition block returns true.
  # Designed to be used inside a before block in InSpec describe statements.
  #
  # @param max_retries [Integer] Maximum number of retry attempts (default: 10)
  # @param retry_delay [Integer] Seconds to wait between retries (default: 5)
  # @param description [String] Optional description for logging (default: nil)
  # @yield Block that returns true when condition is met, false otherwise
  # @return [Boolean] true if condition was met, false if retries exhausted
  #
  def wait_until(max_retries: 10, retry_delay: 5, description: nil)
    desc_text = description ? " (#{description})" : ""

    max_retries.times do |attempt|
      puts "Waiting for condition [#{desc_text}]: attempt #{attempt + 1}/#{max_retries}"
      begin
        if yield
          puts "Condition met: #{desc_text}"
          return true
        end
      rescue StandardError => e
        puts "Condition check failed with error, will retry after #{retry_delay}s: #{e.message}"
      end
      sleep retry_delay if attempt < max_retries - 1
    end
    puts "Condition not met after #{max_retries} attempts: #{desc_text}"
    false
  end

  # Waits for a shell command to succeed (exit status 0).
  # Designed to be used inside a before block in InSpec describe statements.
  #
  # @param cmd [String] The shell command to execute
  # @param max_retries [Integer] Maximum number of retry attempts (default: 10)
  # @param retry_delay [Integer] Seconds to wait between retries (default: 5)
  # @param timeout [Integer] Timeout in seconds for each command (default: 60)
  # @return [Boolean] true if command succeeded, false if retries exhausted
  #
  def wait_for_command(cmd, max_retries: 10, retry_delay: 5, timeout: 60)
    wait_until(max_retries: max_retries, retry_delay: retry_delay, description: cmd) do
      result = inspec.command("timeout #{timeout} #{cmd}")
      result.exit_status == 0
    end
  end
end
