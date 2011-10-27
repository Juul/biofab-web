module PlateHelper

  def row_to_letter(row_number)
    return '' if (row_number < 1) || (row_number > 26)
    return (row_number + 64).chr
  end

end
