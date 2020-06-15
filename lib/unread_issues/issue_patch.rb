module UnreadIssues
  module IssuePatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do
        has_many :issue_reads, -> { order 'read_date DESC' }, class_name: 'IssueRead', foreign_key: :issue_id, dependent: :delete_all
        has_one :ui_user_read, -> { where "#{IssueRead.table_name}.user_id = #{User.current.id}" }, class_name: 'IssueRead', foreign_key: 'issue_id'
        has_one :user_read_list, -> {where "#{IssueRead.table_name}.user_id = #{Issue.table_name}.assigned_to_id" }, class_name: 'IssueRead', foreign_key: 'issue_id'

        alias_method :css_classes_without_ui, :css_classes
        alias_method :css_classes, :css_classes_with_ui

        before_save :ui_store_necessary_to_make_issue_read
        after_save :ui_make_issue_reed_if_needed

        attr_accessor :ui_skip_css_classes
      end
    end

    module InstanceMethods
      def css_classes_with_ui(user=User.current)
        s = css_classes_without_ui(user)
        return s if self.ui_skip_css_classes
        s << ' unread' if (self.ui_unread)
        s << ' updated' if (self.ui_updated)
        s
      end

      def ui_unread
        self.ui_user_read.nil?
      end

      def ui_updated(updated=self.updated_on)
        !!(self.ui_user_read && self.ui_user_read.read_date && self.updated_on && self.ui_user_read.read_date < updated)
      end

      def ui_read_date
        return nil if (self.ui_user_read.nil?)
        return self.ui_user_read.read_date
      end

      def ui_make_issue_read
        begin
          issue_read = IssueRead.where(user_id: User.current.id, issue_id: self.id).first_or_initialize
          issue_read.read_date = Time.now
          issue_read.save
        rescue ActiveRecord::RecordNotUnique
          issue_read = IssueRead.where(user_id: User.current.id, issue_id: self.id).first
          if issue_read.present?
            issue_read.read_date = Time.now
            issue_read.save
          end
          # nothing
        end
      end

      private

      def ui_store_necessary_to_make_issue_read
        @ui_necessary_to_make_issue_read = self.new_record? || (!self.ui_unread && !self.ui_updated(self.updated_on_changed? ? self.updated_on_was : self.updated_on))
        true
      end

      def ui_make_issue_reed_if_needed
        return unless @ui_necessary_to_make_issue_read
        self.ui_make_issue_read
      end
    end
  end
end
