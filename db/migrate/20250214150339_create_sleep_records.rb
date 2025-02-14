class CreateSleepRecords < ActiveRecord::Migration[7.1]
  def change
    create_table :sleep_records do |t|
      t.references :user, null: false, foreign_key: true
      t.datetime :clock_in
      t.datetime :clock_out
      t.integer :duration

      t.timestamps
    end

    add_index :sleep_records, :created_at
    add_index :sleep_records, :duration
  end
end
