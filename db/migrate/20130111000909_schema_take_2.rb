class SchemaTake2 < ActiveRecord::Migration
  def up
    create_table "games", :force => true do |t|
      t.integer  "board"
      t.integer  "status"
      t.integer  "moves", :limit => 8
      t.datetime "created_at", :null => false
      t.datetime "updated_at", :null => false
    end
  end

  def down
  end
end
