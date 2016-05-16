#!/usr/bin/env bash

bosh ssh s2 0 <<'ENDSSH'
  sudo sed -i -- 's/192\.168\.50\.1/10\.244\.0\.154/g' '/var/vcap/jobs/route_registrar/config/registrar_settings.yml' && \
  sudo /var/vcap/bosh/bin/monit start cloud_controller_ng && \
  sudo /var/vcap/bosh/bin/monit restart route_registrar
ENDSSH
