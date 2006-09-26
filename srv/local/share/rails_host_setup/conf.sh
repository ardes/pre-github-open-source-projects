mkdir #{$SITEPATH}/conf 2>/dev/null
chown -R root #{$SITEPATH}/conf
chgrp -R psaserv #{$SITEPATH}/conf

cp -u #{$SRC_DIR}/lighttpd.conf #{$SITEPATH}/conf
cp -u #{$SRC_DIR}/vhost.conf #{$SITEPATH}/conf
#{$SSL ? "cp -u #{$SRC_DIR}/vhost.conf #{$SITEPATH}/conf/vhost_ssl.conf" : ""}

chmod -R 750 #{$SITEPATH}/conf
