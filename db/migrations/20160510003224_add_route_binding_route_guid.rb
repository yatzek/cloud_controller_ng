Sequel.migration do
  change do
    alter_table(:route_bindings) do
      drop_foreign_key [:route_id], name: :route_bindings_route_id_fkey
      drop_column :route_id

      add_column :route_guid, String, null: false # some length or something
    end
  end
end
