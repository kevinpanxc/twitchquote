class CreateAnnouncements < ActiveRecord::Migration
  def change
    create_table :announcements do |t|
        t.text :content, :limit => nil
        t.boolean :expired

        t.timestamps
    end
  end
end