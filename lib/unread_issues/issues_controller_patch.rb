module UnreadIssues
  module IssuesControllerPatch
    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do
        after_action :make_issue_read, only: [:show]
      end
    end

    module InstanceMethods

      def make_issue_read
        issue_read = IssueRead.where(user_id: User.current.id, issue_id: @issue.id).first_or_create
        issue_read.read_date = Time.now
        issue_read.save
      end
    end
  end
end
