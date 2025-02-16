class OptimizeSleepRecordsIndex < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    remove_index :sleep_records, :created_at, if_exists: true
    remove_index :sleep_records, :duration, if_exists: true

    add_index :sleep_records,
              [:created_at, :duration, :id],
              if_not_exists: true,
              include: [:user_id],
              name: "idx_sleep_records_optimized",
              algorithm: :concurrently
  end
end
