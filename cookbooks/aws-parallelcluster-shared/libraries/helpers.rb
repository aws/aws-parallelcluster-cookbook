class NilClass
  def blank?
    true
  end
end

class String
  def blank?
    strip.empty?
  end
end
