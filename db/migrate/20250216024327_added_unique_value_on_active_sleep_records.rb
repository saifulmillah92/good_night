class AddedUniqueValueOnActiveSleepRecords < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_index :sleep_records,
              :user_id,
              unique: true,
              where: "clock_out IS NULL",
              name: "index_sleep_records_on_user_id_where_active",
              algorithm: :concurrently
  end
end
