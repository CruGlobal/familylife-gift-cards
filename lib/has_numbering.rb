module HasNumbering
  def numbering_regex_str
    # add brackets around the x's so that it can be extracted, and use \d instead of x
    numbering.gsub(/x+/) { |xs| "(#{xs.gsub("x", "\\d")})" }
  end

  def numbering_regex
    @numbering_regex ||= /#{numbering_regex_str}/
  end
end
