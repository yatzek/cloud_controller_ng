Sequel.migration do
  change do
    alter_table(:service_bindings) do
      drop_foreign_key [:app_id], name: :fk_service_bindings_app_id
      drop_index [:app_id, :service_instance_id], :name => :sb_app_id_srv_inst_id_index
      drop_column :app_id

      add_column :app_guid, String, null: false # some length or something
      add_index [:app_guid, :service_instance_id], unique: true
    end
  end
end
