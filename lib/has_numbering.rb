module HasNumbering
  def numbering_regex_str
    numbering.gsub(/x+/) { |xs| "(#{xs.gsub("x", "\\d")})" }
  end

  def numbering_regex
    # add brackets around the x's so that it can be extracted, and use \d instead of x
    @numbering_regex ||= /#{numbering_regex_str}/
  end
end
