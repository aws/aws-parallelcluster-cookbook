class RetryHelpers < Inspec.resource(1)
  name 'retry_helpers'

  desc '
    Helper methods for retry logic in InSpec tests
  '
  example '
    retry_helpers.with_retries { some_flaky_operation }
    retry_helpers.with_retries(max_retries: 3, retry_delay: 2) { some_flaky_operation }
  '

  # Executes a block with retry logic for handling transient failures.
  #
  # @param max_retries [Integer] Maximum number of retry attempts (default: 10)
  # @param retry_delay [Integer] Seconds to wait between retries (default: 5)
  # @yield The block to execute with retry protection
  # @raise [StandardError] Re-raises the last exception if all retries are exhausted
  #
  def with_retries(max_retries: 10, retry_delay: 5)
    last_exception = nil

    max_retries.times do |attempt|
      begin
        return yield
      rescue StandardError => e
        last_exception = e
        puts "Attempt #{attempt + 1}/#{max_retries} failed: #{e.message}"
        sleep retry_delay if attempt < max_retries - 1
      end
    end

    puts "All #{max_retries} retry attempts exhausted"
    raise last_exception
  end
end
