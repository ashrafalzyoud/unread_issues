class CreateIssueReads < Rails.version < '5.0' ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
	def change
	    create_table :issue_reads do |t|
	    	t.references :user
	    	t.references :issue
		    t.datetime :read_date
		    t.timestamps
		end
	end
end
