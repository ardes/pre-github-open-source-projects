trac-admin #{$TRAC_DIR}/#{$PROJECT} initenv "#{$NAME}" #{$TRAC_DB} svn #{$SVN_DIR}/#{$PROJECT} #{$TRAC_TEMPLATES_DIR}
chown -R apache.apache #{$TRAC_DIR}/#{$PROJECT}
