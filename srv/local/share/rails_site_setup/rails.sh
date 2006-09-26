mkdir #{$SITEPATH}/rails 2>/dev/null

chown -R #{$USERNAME} #{$SITEPATH}/rails
chgrp -R psaserv #{$SITEPATH}/rails
chmod -R u+rwx #{$SITEPATH}/rails
chmod -R g+rs #{$SITEPATH}/rails
chmod -R o-rwx #{$SITEPATH}/rails
