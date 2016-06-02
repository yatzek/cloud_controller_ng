Sequel.migration do
  up do
    v2_apps = self[:apps].where(:app_guid => nil).select(:guid, :space_id)
    v2_apps.each do |v2_app|
      run <<-SQL
        UPDATE apps
        SET app_guid='#{v2_app[:guid]}'
        WHERE guid='#{v2_app[:guid]}';
      SQL
    end
  end
end
