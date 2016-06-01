Sequel.migration do
  up do
    v2_apps = self[:apps].where(:app_guid => nil).select(:guid, :space_id)
    v2_apps.each do |v2_app|
      space_guid = self[:spaces].where(:id => v2_app[:space_id]).first[:guid]
      run <<-SQL
        UPDATE apps_v3
        SET space_guid='#{space_guid}'
        WHERE guid='#{v2_app[:guid]}';
      SQL
    end
  end
end
