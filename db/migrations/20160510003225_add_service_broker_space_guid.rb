Sequel.migration do
  change do
    alter_table(:service_brokers) do
      drop_foreign_key [:space_id], name: :service_brokers_space_id_fkey
      drop_column :space_id

      add_column :space_guid, String
    end
  end
end
