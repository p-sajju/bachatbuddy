# frozen_string_literal: true

class AddNamePartsAndPhoneToUsers < ActiveRecord::Migration[8.0]
  def up
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    add_column :users, :phone_number, :string

    # Backfill from legacy full name
    say_with_time "backfill first_name/last_name from name" do
      execute <<~SQL.squish
        UPDATE users
        SET
          first_name = CASE
            WHEN position(' ' in trim(name)) > 0
              THEN left(trim(name), position(' ' in trim(name)) - 1)
            ELSE trim(name)
          END,
          last_name = CASE
            WHEN position(' ' in trim(name)) > 0
              THEN trim(substring(trim(name) from position(' ' in trim(name)) + 1))
            ELSE ''
          END
        WHERE first_name IS NULL
      SQL
    end

    change_column_null :users, :first_name, false
    change_column_null :users, :last_name, false

    execute "UPDATE users SET phone_number = '0000000000' WHERE phone_number IS NULL OR phone_number = ''"
    change_column_null :users, :phone_number, false

    add_index :users, :phone_number
  end

  def down
    remove_index :users, :phone_number
    remove_column :users, :phone_number
    remove_column :users, :last_name
    remove_column :users, :first_name
  end
end
