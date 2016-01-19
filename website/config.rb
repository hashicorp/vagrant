set :base_url, "https://www.vagrantup.com/"

activate :hashicorp do |h|
  h.name = "vagrant"
  h.version = "1.8.1"
  h.github_slug = "mitchellh/vagrant"
end

helpers do
  # This helps by setting the "active" class for sidebar nav elements
  # if the YAML frontmatter matches the expected value.
  def sidebar_current(expected)
    current = current_page.data.sidebar_current || ""
    if current.start_with?(expected)
      return " class=\"active\""
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

  def body_classes
    classify = ->(s) { s.downcase.gsub(/[^a-zA-Z0-9]/, "-").squeeze("-") }

    classes = []

    if current_page.data.page_title
      classes << "page-#{classify.call(current_page.data.page_title)}"
    else
      classes << "page-home"
    end

    if current_page.data.layout
      classes << "layout-#{classify.call(current_page.data.layout)}"
    end

    return classes.join(" ")
  end
  # "home layout-#{current_page.data.layout}"

  # Get the title for the page.
  #
  # @param [Middleman::Page] page
  #
  # @return [String]
  def title_for(page)
    if page && page.data.page_title
      return "#{page.data.page_title} - Vagrant by HashiCorp"
    end

    "Vagrant by HashiCorp"
  end
end
