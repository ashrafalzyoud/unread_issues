module UiMenuHelper
  def ui_my_issues_url(project=nil)
    url_for(controller: :issues, action: :index, query_id: (Setting.plugin_unread_issues || {})['assigned_issues'].to_i, project_id: nil)
  end
  def ui_my_assigned_issues_url(project=nil)
    url_for(controller: :issues, action: :index, query_id: (Setting.plugin_unread_issues || {})['assigned_issues'].to_i, project_id: nil)
  end
  def ui_my_updated_issues_url(project=nil)
    url_for(controller: :issues, action: :index, query_id: (Setting.plugin_unread_issues || {})['updated_issues'].to_i, project_id: nil)
  end
  def ui_my_unread_issues_url(project=nil)
    url_for(controller: :issues, action: :index, query_id: (Setting.plugin_unread_issues || {})['unread_issues'].to_i, project_id: nil)
  end
end
