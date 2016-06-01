Sequel.migration do
  up do
    run <<-SQL
      INSERT INTO apps_v3 (guid, name, desired_state, salt, encrypted_environment_variables, created_at, updated_at)
      SELECT guid, name, state, salt, encrypted_environment_json, created_at, updated_at
      FROM apps
      WHERE app_guid IS null
    SQL
  end
end
