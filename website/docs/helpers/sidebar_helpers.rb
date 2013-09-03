module SidebarHelpers
  # This helps by setting the "current" class for sidebar nav elements
  # if the YAML frontmatter matches the expected value.
  def sidebar_current(expected)
    current = current_page.data.sidebar_current
    if current == expected || sidebar_section == expected
      return " class=\"current\""
    else
      return ""
    end
  end

  # This returns the overall section of the documentation we're on.
  def sidebar_section
    current = current_page.data.sidebar_current
    return "" if !current
    current.split("-")[0]
  end
end
