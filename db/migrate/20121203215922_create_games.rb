class CreateGames < ActiveRecord::Migration
  def change
    create_table :games do |t|
      t.string :state
      t.integer :status
      t.string :moves

      t.timestamps
    end
  end
end
