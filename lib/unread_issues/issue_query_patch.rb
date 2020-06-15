module UnreadIssues
  module IssueQueryPatch
    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do
        before_destroy :ui_validate_settings_before_destroy

        alias_method :issues_without_ui, :issues
        alias_method :issues, :issues_with_ui

        alias_method :issue_ids_without_ui, :issue_ids
        alias_method :issue_ids, :issue_ids_with_ui

        alias_method :available_columns_without_ui, :available_columns
        alias_method :available_columns, :available_columns_with_ui

        alias_method :initialize_available_filters_without_ui, :initialize_available_filters
        alias_method :initialize_available_filters, :initialize_available_filters_with_ui

        alias_method :joins_for_order_statement_without_ui, :joins_for_order_statement
        alias_method :joins_for_order_statement, :joins_for_order_statement_with_ui

        alias_method :result_count_by_group_without_ui, :result_count_by_group
        alias_method :result_count_by_group, :result_count_by_group_with_ui

        base.add_available_column(QueryColumn.new(:ui_unread, sortable: Proc.new { "case when (#{IssueStatus.table_name}.is_closed = #{connection.quoted_false}) and ui_ir.id is null then 1 else 0 end" }, groupable: true, caption: :unread_issues_label_filter_unread))
        base.add_available_column(QueryColumn.new(:ui_updated, sortable: Proc.new { "case when (#{IssueStatus.table_name}.is_closed = #{connection.quoted_false}) and ui_ir.read_date < #{Issue.table_name}.updated_on then 1 else 0 end" }, groupable: true, caption: :unread_issues_label_filter_updated))
      end
    end

    module InstanceMethods
      def issues_with_ui(options={})
        options[:include] ||= [ ]
        unless (options[:include].include?(:ui_user_read))
          options[:include] << :ui_user_read
        end
        issues_without_ui(options)
      end

      def issue_ids_with_ui(options={})
        options[:include] ||= [ ]
        unless options[:include].include?(:ui_user_read)
          options[:include] << :ui_user_read
        end
        issue_ids_without_ui(options)
      end

      def available_columns_with_ui
        return available_columns_without_ui if @available_columns
        available_columns_without_ui
        @available_columns << QueryColumn.new(:ui_unread,
          sortable: "case when (#{IssueStatus.table_name}.is_closed = #{IssueQuery.connection.quoted_false}) and ui_ir.id is null then #{IssueQuery.connection.quoted_true} else #{IssueQuery.connection.quoted_false} end",
          groupable: "case when (#{IssueStatus.table_name}.is_closed = #{IssueQuery.connection.quoted_false}) and ui_ir.id is null then #{IssueQuery.connection.quoted_true} else #{IssueQuery.connection.quoted_false} end",
          caption: :unread_issues_label_filter_unread)
        @available_columns << QueryColumn.new(:ui_updated,
          sortable: "case when (#{IssueStatus.table_name}.is_closed = #{IssueQuery.connection.quoted_false}) and ui_ir.read_date < #{Issue.table_name}.updated_on then #{IssueQuery.connection.quoted_true} else #{IssueQuery.connection.quoted_false} end",
          groupable: "case when (#{IssueStatus.table_name}.is_closed = #{IssueQuery.connection.quoted_false}) and ui_ir.read_date < #{Issue.table_name}.updated_on then #{IssueQuery.connection.quoted_true} else #{IssueQuery.connection.quoted_false} end",
          caption: :unread_issues_label_filter_updated)
      end

      def result_count_by_group_with_ui
        res = result_count_by_group_without_ui
        if self.group_by_column && %w(ui_unread ui_updated).include?(self.group_by_column.name.to_s)
          res.transform_keys { |key| key.to_i == 1 }
        else
          res
        end
      end

      def sql_for_ui_unread_field(field, operator, value)
        return '' if (value == [ ])
        case operator
          when '=', '!'
            if value.size == 1 && (value.include?('1') || value.include?('0'))
              if operator == '!'
                if value.include?('1')
                  value = ['0']
                else
                  value = ['1']
                end
              end
              "case when (
                    NOT EXISTS(
                      SELECT * FROM #{IssueRead.table_name} ui_ir
                        WHERE ui_ir.issue_id = #{Issue.table_name}.id and ui_ir.user_id = #{User.current.id})
                  ) then 1 else 0 end in (#{value.join(',')})"
            else
              if operator == '!'
                '(1=0)'
              else
                ''
              end
            end
        end
      end

      def sql_for_ui_updated_field(field, operator, value)
        return '' if (value == [ ])
        case operator
          when '=', '!'
            if value.size == 1 && (value.include?('1') || value.include?('0'))
              if operator == '!'
                if value.include?('1')
                  value = ['0']
                else
                  value = ['1']
                end
              end
              "EXISTS(
                SELECT * FROM #{IssueRead.table_name} ui_ir
                  WHERE ui_ir.issue_id = #{Issue.table_name}.id and
                        ui_ir.user_id = #{User.current.id} and
                        ui_ir.read_date #{value.include?('1') ? '<' : '>'} #{Issue.table_name}.updated_on)"
            else
              if operator == '!'
                '(1=0)'
              else
                ''
              end
            end
        end
      end

      def initialize_available_filters_with_ui
        initialize_available_filters_without_ui

        add_available_filter('ui_unread', type: :list, values: [[l(:general_text_Yes), '1'], [l(:general_text_No), '0']], name: l(:unread_issues_label_filter_unread))
        add_available_filter('ui_updated', type: :list, values: [[l(:general_text_Yes), '1'], [l(:general_text_No), '0']], name: l(:unread_issues_label_filter_updated))
      end

      def joins_for_order_statement_with_ui(order_options)
        joins = [joins_for_order_statement_without_ui(order_options)]

        if order_options
          if order_options.include?(' ui_ir.')
            joins << "LEFT JOIN #{IssueRead.table_name} ui_ir ON ui_ir.issue_id = #{Issue.table_name}.id and ui_ir.user_id = #{User.current.id}"
          end
        end

        joins.compact!
        joins.any? ? joins.join(' ') : nil
      end

      private

      def ui_validate_settings_before_destroy
        if (Setting.plugin_unread_issues || {})['assigned_issues'].to_i == self.id
          self.errors.add(:base, l(:ui_error_cant_delete_query_used_in_plugin_settings, link: User.current.admin? ? "<a href='#{Redmine::Utils.relative_url_root}/settings/plugin/unread_issues'>#{l(:ui_label_module_settings_custom)}</a>" : l(:ui_label_module_settings_custom)).html_safe)
          throw(:abort)
        end
      end

    end
  end
end
