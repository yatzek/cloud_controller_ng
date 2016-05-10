Sequel.migration do
  change do
    alter_table(:service_instances) do
      drop_foreign_key [:space_id], name: :service_instances_space_id
      drop_index [:space_id, :name], :name => :si_space_id_name_index
      drop_column :space_id

      add_column :space_guid, String, null: false # some length or something
      add_index [:space_guid, :name], unique: true
    end
  end
end
