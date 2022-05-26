Redmine::Plugin.register :unread_issues do
  name 'Unread Issues plugin'
  author 'Vladimir Pitin, Danil Kukhlevskiy, !Lucky, Tilman19'
  description 'This is a plugin for Redmine, that marks unread issues'
    version '0.0.3'
    url 'http://rmplus.pro/redmine/plugins/unread_issues'
    author_url 'http://rmplus.pro'
  directory __dir__
  requires_redmine version_or_higher: '4.0'

  settings partial: 'unread_issues/settings',
    default: {
      'assigned_issues' => '',
      'unread_issues' => '',
      'updated_issues' => ''
    }

  project_module :issue_tracking do
    permission :view_issue_view_stats, issue_view_stats: [:view_stats]
  end

  if Redmine::Plugin.installed?(:magic_my_page)
    #delete_menu_item :top_menu, :my_page
  end
  menu :top_menu, :ui_my_assigned_issues, :ui_my_assigned_issues_url, :caption => Proc.new { User.current.ui_my_assigned_issues_caption }, after: :home, if: Proc.new { User.current.logged? }
  menu :top_menu, :ui_my_unread_issues, :ui_my_unread_issues_url, :caption => Proc.new { User.current.ui_my_unread_issues_caption }, after: :ui_my_assigned_issues, if: Proc.new { User.current.logged? }
  menu :top_menu, :ui_my_updated_issues, :ui_my_updated_issues_url, :caption => Proc.new { User.current.ui_my_updated_issues_caption }, after: :ui_my_unread_issues, if: Proc.new { User.current.logged? }
end

def init()
  require File.expand_path('lib/unread_issues/hooks_views.rb', __dir__)


  unless Issue.included_modules.include?(UnreadIssues::IssuePatch)
    Issue.send(:include, UnreadIssues::IssuePatch)
  end
  unless User.included_modules.include?(UnreadIssues::UserPatch)
    User.send(:include, UnreadIssues::UserPatch)
  end
  unless IssuesController.included_modules.include?(UnreadIssues::IssuesControllerPatch)
    IssuesController.send(:include, UnreadIssues::IssuesControllerPatch)
  end
  unless IssueQuery.included_modules.include?(UnreadIssues::IssueQueryPatch)
    IssueQuery.send(:include, UnreadIssues::IssueQueryPatch)
  end
  unless QueriesController.included_modules.include?(UnreadIssues::QueriesControllerPatch)
    QueriesController.send(:include, UnreadIssues::QueriesControllerPatch)
  end
  ActionView::Base.send(:include, UiMenuHelper)

  #Acl::Settings.append_setting('enable_javascript_patches', :unread_issues)
  #Acl::Settings.append_setting('enable_ajax_counters', :unread_issues)
end

if Rails.version > '6.0'
    init()
    return
else
    Rails.configuration.to_prepare do
        init()
    end
end

