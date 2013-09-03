module SidebarHelpers
  # This helps by setting the "current" class for sidebar nav elements
  # if the YAML frontmatter matches the expected value.
  def sidebar_current(expected)
    actual = current_page.data.sidebar_current
    if actual && actual == expected
      return " class=\"current\""
    else
      return ""
    end
  end
end
