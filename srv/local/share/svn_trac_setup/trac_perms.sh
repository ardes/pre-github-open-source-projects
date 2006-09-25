trac-admin /srv/trac/#{$PROJECT} permission remove anonymous '*'
trac-admin /srv/trac/#{$PROJECT} permission remove developer '*'
trac-admin /srv/trac/#{$PROJECT} permission remove designer '*'
trac-admin /srv/trac/#{$PROJECT} permission remove client '*'
trac-admin /srv/trac/#{$PROJECT} permission remove ian '*'
trac-admin /srv/trac/#{$PROJECT} permission remove ray '*'

trac-admin /srv/trac/#{$PROJECT} permission add developer TRAC_ADMIN

trac-admin /srv/trac/#{$PROJECT} permission add designer \
  TIMELINE_VIEW SEARCH_VIEW BROWSER_VIEW LOG_VIEW FILE_VIEW CHANGESET_VIEW \
  WIKI_ADMIN MILESTONE_ADMIN ROADMAP_ADMIN TICKET_ADMIN REPORT_ADMIN \
  GANTT_ADMIN

trac-admin /srv/trac/#{$PROJECT} permission add client \
  BROWSER_VIEW CHANGESET_VIEW FILE_VIEW LOG_VIEW MILESTONE_VIEW \
  REPORT_SQL_VIEW REPORT_VIEW ROADMAP_VIEW SEARCH_VIEW TICKET_CREATE \
  TICKET_MODIFY TICKET_VIEW TIMELINE_VIEW WIKI_CREATE WIKI_MODIFY WIKI_VIEW \
  GANTT_VIEW
  
trac-admin /srv/trac/#{$PROJECT} permission add ian developer
trac-admin /srv/trac/#{$PROJECT} permission add ray designer