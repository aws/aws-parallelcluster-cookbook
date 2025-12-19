# Helper method to retry flaky InSpec checks
def with_retry(retries: 3, delay: 5)
  attempts = 0
  begin
    attempts += 1
    yield
  rescue => e
    if attempts < retries
      sleep delay
      retry
    else
      raise e
    end
  end
end
